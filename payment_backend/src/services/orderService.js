const dayjs = require('dayjs');
const crypto = require('crypto');
const { withTx, pool, redis } = require('../db');
const { getSku } = require('../plans');
const { buildAppPayOrderString } = require('../providers/alipay');
const { createAppOrder } = require('../providers/wechat');
const { config } = require('../config');

async function createOrder({ userId, sku, channel }) {
  const skuMeta = getSku(sku);
  if (!skuMeta) {
    throw new Error('Unsupported SKU');
  }
  if (!['alipay', 'wechat'].includes(channel)) {
    throw new Error('Unsupported payment channel');
  }

  const orderId = `ORD${Date.now()}${Math.floor(Math.random() * 10000)}`;
  const subject =
    skuMeta.type === 'membership'
      ? `会员订阅-${skuMeta.sku}`
      : `字数包购买-${skuMeta.sku}`;
  const now = new Date();
  const expiresAt = dayjs(now).add(config.orderExpireMinutes, 'minute').toDate();

  await pool.query(
    `INSERT INTO payment_orders
      (id, user_id, sku, order_type, channel, subject, amount_fen, status, expires_at, created_at, updated_at)
     VALUES ($1,$2,$3,$4,$5,$6,$7,'CREATED',$8,$9,$9)`,
    [orderId, userId, sku, skuMeta.type, channel, subject, skuMeta.priceFen, expiresAt, now],
  );

  let payPayload = null;
  if (channel === 'alipay') {
    payPayload = {
      orderString: buildAppPayOrderString({
        orderId,
        userId,
        sku,
        orderType: skuMeta.type,
        amountFen: skuMeta.priceFen,
        subject,
      }),
    };
  } else {
    payPayload = await createAppOrder({
      orderId,
      userId,
      sku,
      orderType: skuMeta.type,
      amountFen: skuMeta.priceFen,
      subject,
    });
  }

  return {
    orderId,
    channel,
    sku,
    orderType: skuMeta.type,
    amountFen: skuMeta.priceFen,
    expiresAt: expiresAt.toISOString(),
    payPayload,
  };
}

async function getOrder(orderId, userId) {
  const result = await pool.query(
    `SELECT id, user_id, sku, order_type, channel, subject, amount_fen, status, provider_txn_id, paid_at, expires_at, created_at, updated_at
     FROM payment_orders WHERE id = $1 AND user_id = $2`,
    [orderId, userId],
  );
  return result.rows[0] || null;
}

async function grantEntitlementTx(client, order) {
  const skuMeta = getSku(order.sku);
  if (!skuMeta) throw new Error('Unknown SKU in grantEntitlementTx');

  const now = new Date();
  if (skuMeta.type === 'membership') {
    const exists = await client.query(
      'SELECT user_id, is_lifetime, expire_at FROM user_memberships WHERE user_id = $1 FOR UPDATE',
      [order.user_id],
    );

    let isLifetime = false;
    let expireAt = null;
    if (skuMeta.days == null) {
      isLifetime = true;
    } else {
      const base = exists.rows[0]?.expire_at && dayjs(exists.rows[0].expire_at).isAfter(now)
        ? dayjs(exists.rows[0].expire_at)
        : dayjs(now);
      expireAt = base.add(skuMeta.days, 'day').toDate();
    }

    await client.query(
      `INSERT INTO user_memberships
        (user_id, sku, is_active, is_lifetime, start_at, expire_at, updated_at, created_at)
       VALUES ($1,$2,true,$3,$4,$5,$4,$4)
       ON CONFLICT (user_id)
       DO UPDATE SET
         sku = EXCLUDED.sku,
         is_active = true,
         is_lifetime = EXCLUDED.is_lifetime OR user_memberships.is_lifetime,
         start_at = COALESCE(user_memberships.start_at, EXCLUDED.start_at),
         expire_at = CASE
           WHEN EXCLUDED.is_lifetime THEN NULL
           WHEN user_memberships.is_lifetime THEN NULL
           ELSE GREATEST(COALESCE(user_memberships.expire_at, EXCLUDED.expire_at), EXCLUDED.expire_at)
         END,
         updated_at = EXCLUDED.updated_at`,
      [order.user_id, order.sku, isLifetime, now, expireAt],
    );

    if (skuMeta.bonusWords > 0) {
      await client.query(
        `INSERT INTO user_word_wallets
          (user_id, vip_gift_words, purchased_words, reward_words, consumed_words, updated_at, created_at)
         VALUES ($1,$2,0,0,0,$3,$3)
         ON CONFLICT (user_id)
         DO UPDATE SET
           vip_gift_words = user_word_wallets.vip_gift_words + EXCLUDED.vip_gift_words,
           updated_at = EXCLUDED.updated_at`,
        [order.user_id, skuMeta.bonusWords, now],
      );
    }
    return;
  }

  await client.query(
    `INSERT INTO user_word_wallets
      (user_id, vip_gift_words, purchased_words, reward_words, consumed_words, updated_at, created_at)
     VALUES ($1,0,$2,0,0,$3,$3)
     ON CONFLICT (user_id)
     DO UPDATE SET
       purchased_words = user_word_wallets.purchased_words + EXCLUDED.purchased_words,
       updated_at = EXCLUDED.updated_at`,
    [order.user_id, skuMeta.words, now],
  );

  await client.query(
    `INSERT INTO user_word_lots
      (id, user_id, order_id, words, purchased_at, expire_at, created_at)
     VALUES ($1,$2,$3,$4,$5,$6,$5)`,
    [crypto.randomUUID(), order.user_id, order.id, skuMeta.words, now, dayjs(now).add(skuMeta.validityDays, 'day').toDate()],
  );
}

async function markOrderPaid({ orderId, providerTxnId, rawNotify }) {
  const lockKey = `order_paid_lock:${orderId}`;
  if (redis) {
    const ok = await redis.set(lockKey, '1', 'EX', 20, 'NX');
    if (!ok) return;
  }

  try {
    await withTx(async (client) => {
      const result = await client.query(
        `SELECT * FROM payment_orders WHERE id = $1 FOR UPDATE`,
        [orderId],
      );
      const order = result.rows[0];
      if (!order) throw new Error('order_not_found');

      if (order.status === 'PAID') return;
      if (order.status === 'CLOSED' || order.status === 'EXPIRED' || order.status === 'FAILED') {
        throw new Error(`order_status_invalid:${order.status}`);
      }

      const now = new Date();
      await client.query(
        `UPDATE payment_orders
         SET status = 'PAID', provider_txn_id = $2, paid_at = $3, raw_notify = $4, updated_at = $3
         WHERE id = $1`,
        [orderId, providerTxnId, now, rawNotify || null],
      );

      await grantEntitlementTx(client, order);
    });
  } finally {
    if (redis) {
      await redis.del(lockKey);
    }
  }
}

async function getUserBillingState(userId) {
  const [membershipRes, walletRes] = await Promise.all([
    pool.query(
      `SELECT user_id, sku, is_active, is_lifetime, start_at, expire_at, updated_at
       FROM user_memberships WHERE user_id = $1`,
      [userId],
    ),
    pool.query(
      `SELECT user_id, vip_gift_words, purchased_words, reward_words, consumed_words, updated_at
       FROM user_word_wallets WHERE user_id = $1`,
      [userId],
    ),
  ]);

  const m = membershipRes.rows[0] || null;
  const w = walletRes.rows[0] || {
    vip_gift_words: 0,
    purchased_words: 0,
    reward_words: 0,
    consumed_words: 0,
  };

  const now = dayjs();
  const isMembershipActive = !!m && (
    m.is_lifetime ||
    (m.is_active && m.expire_at && dayjs(m.expire_at).isAfter(now.subtract(config.membershipSyncGraceSeconds, 'second')))
  );

  return {
    membership: m
      ? {
          productId: m.sku,
          isActive: isMembershipActive,
          isLifetime: !!m.is_lifetime,
          purchaseDate: m.start_at ? dayjs(m.start_at).toISOString() : null,
          expiryDate: m.expire_at ? dayjs(m.expire_at).toISOString() : null,
        }
      : null,
    wallet: {
      vipGiftWords: Number(w.vip_gift_words || 0),
      purchasedWords: Number(w.purchased_words || 0),
      rewardWords: Number(w.reward_words || 0),
      consumedWords: Number(w.consumed_words || 0),
    },
  };
}

module.exports = {
  createOrder,
  getOrder,
  markOrderPaid,
  getUserBillingState,
};
