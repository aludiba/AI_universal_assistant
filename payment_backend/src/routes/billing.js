const express = require('express');
const { z } = require('zod');
const { verifyNotifyForm } = require('../providers/alipay');
const { decryptWechatResource, verifyWechatCallback } = require('../providers/wechat');
const { createOrder, getOrder, markOrderPaid, getUserBillingState } = require('../services/orderService');

const router = express.Router();

const createOrderSchema = z.object({
  userId: z.string().min(1).max(64),
  sku: z.string().min(1).max(64),
  channel: z.enum(['alipay', 'wechat']),
});

router.post('/order', async (req, res) => {
  try {
    const payload = createOrderSchema.parse(req.body);
    const order = await createOrder(payload);
    return res.json({ ok: true, data: order });
  } catch (error) {
    req.log.error({ err: error }, 'create order failed');
    return res.status(400).json({ ok: false, error: error.message || 'invalid_request' });
  }
});

router.get('/order/:orderId', async (req, res) => {
  const { orderId } = req.params;
  const userId = `${req.query.userId || ''}`;
  if (!orderId || !userId) {
    return res.status(400).json({ ok: false, error: 'orderId_and_userId_required' });
  }
  const order = await getOrder(orderId, userId);
  if (!order) {
    return res.status(404).json({ ok: false, error: 'order_not_found' });
  }
  return res.json({ ok: true, data: order });
});

router.get('/state/:userId', async (req, res) => {
  const userId = req.params.userId;
  if (!userId) {
    return res.status(400).json({ ok: false, error: 'userId_required' });
  }
  const state = await getUserBillingState(userId);
  return res.json({ ok: true, data: state });
});

router.post('/alipay/notify', async (req, res) => {
  try {
    const form = req.body || {};
    if (!verifyNotifyForm(form)) {
      req.log.warn({ body: form }, 'alipay verify failed');
      return res.status(400).send('fail');
    }

    const tradeStatus = `${form.trade_status || ''}`;
    if (tradeStatus !== 'TRADE_SUCCESS' && tradeStatus !== 'TRADE_FINISHED') {
      return res.send('success');
    }

    await markOrderPaid({
      orderId: `${form.out_trade_no || ''}`,
      providerTxnId: `${form.trade_no || ''}`,
      rawNotify: JSON.stringify(form),
    });
    return res.send('success');
  } catch (error) {
    req.log.error({ err: error }, 'alipay notify failed');
    return res.status(500).send('fail');
  }
});

router.post('/wechat/notify', async (req, res) => {
  try {
    const rawBody = req.rawBodyString || JSON.stringify(req.body || {});
    const verified = verifyWechatCallback(req.headers, rawBody);
    if (!verified) {
      req.log.warn({ headers: req.headers }, 'wechat callback signature invalid');
      return res.status(401).json({ code: 'FAIL', message: 'signature invalid' });
    }

    const body = req.body || {};
    if (!body.resource) {
      return res.status(400).json({ code: 'FAIL', message: 'invalid payload' });
    }

    const resource = decryptWechatResource(body.resource);
    await markOrderPaid({
      orderId: `${resource.out_trade_no || ''}`,
      providerTxnId: `${resource.transaction_id || ''}`,
      rawNotify: JSON.stringify(resource),
    });

    return res.json({ code: 'SUCCESS', message: '成功' });
  } catch (error) {
    req.log.error({ err: error }, 'wechat notify failed');
    return res.status(500).json({ code: 'FAIL', message: 'internal error' });
  }
});

module.exports = { billingRouter: router };
