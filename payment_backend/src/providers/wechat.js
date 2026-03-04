const axios = require('axios');
const dayjs = require('dayjs');
const { config } = require('../config');
const {
  rsaSignSha256,
  rsaVerifySha256,
  aes256GcmDecrypt,
  randomString,
} = require('../utils/crypto');

function buildAuthorization(method, path, body) {
  const nonceStr = randomString(16);
  const timestamp = `${Math.floor(Date.now() / 1000)}`;
  const message = `${method}\n${path}\n${timestamp}\n${nonceStr}\n${body}\n`;
  const signature = rsaSignSha256(message, config.wechat.privateKey);
  return {
    nonceStr,
    timestamp,
    value:
      `WECHATPAY2-SHA256-RSA2048 mchid="${config.wechat.mchId}",` +
      `serial_no="${config.wechat.serialNo}",nonce_str="${nonceStr}",` +
      `timestamp="${timestamp}",signature="${signature}"`,
  };
}

async function createAppOrder(order) {
  const path = '/v3/pay/transactions/app';
  const payload = {
    appid: config.wechat.appId,
    mchid: config.wechat.mchId,
    out_trade_no: order.orderId,
    description: order.subject,
    notify_url: `${config.callbackBaseUrl}${config.wechat.notifyPath}`,
    time_expire: dayjs().add(config.orderExpireMinutes, 'minute').toISOString(),
    amount: {
      total: order.amountFen,
      currency: 'CNY',
    },
    attach: JSON.stringify({
      sku: order.sku,
      userId: order.userId,
      orderType: order.orderType,
    }),
  };
  const body = JSON.stringify(payload);
  const auth = buildAuthorization('POST', path, body);
  const response = await axios.post(`${config.wechat.gateway}${path}`, payload, {
    timeout: 15000,
    headers: {
      Authorization: auth.value,
      Accept: 'application/json',
      'User-Agent': 'ai-writing-cat-billing/1.0',
      'Content-Type': 'application/json',
    },
  });

  const prepayId = response.data.prepay_id;
  if (!prepayId) {
    throw new Error('WeChat prepay_id missing');
  }
  const appNonce = randomString(16);
  const appTimestamp = `${Math.floor(Date.now() / 1000)}`;
  const packageValue = 'Sign=WXPay';
  const paySignMessage = `${config.wechat.appId}\n${appTimestamp}\n${appNonce}\n${prepayId}\n`;
  const paySign = rsaSignSha256(paySignMessage, config.wechat.privateKey);

  return {
    appId: config.wechat.appId,
    partnerId: config.wechat.mchId,
    prepayId,
    packageValue,
    nonceStr: appNonce,
    timestamp: Number(appTimestamp),
    sign: paySign,
    signType: 'RSA',
  };
}

function verifyWechatCallback(headers, rawBody) {
  const timestamp = headers['wechatpay-timestamp'];
  const nonce = headers['wechatpay-nonce'];
  const signature = headers['wechatpay-signature'];
  if (!timestamp || !nonce || !signature) return false;
  const message = `${timestamp}\n${nonce}\n${rawBody}\n`;
  return rsaVerifySha256(message, signature, config.wechat.platformPublicKey);
}

function decryptWechatResource(resource) {
  const plain = aes256GcmDecrypt({
    apiV3Key: config.wechat.apiV3Key,
    associatedData: resource.associated_data || '',
    nonce: resource.nonce,
    ciphertext: resource.ciphertext,
  });
  return JSON.parse(plain);
}

module.exports = {
  createAppOrder,
  verifyWechatCallback,
  decryptWechatResource,
};
