const dayjs = require('dayjs');
const { URLSearchParams } = require('url');
const { config } = require('../config');
const { rsaSignSha256, rsaVerifySha256 } = require('../utils/crypto');

function stringifyBizContent(order) {
  return JSON.stringify({
    subject: order.subject,
    out_trade_no: order.orderId,
    total_amount: (order.amountFen / 100).toFixed(2),
    product_code: 'QUICK_MSECURITY_PAY',
    timeout_express: `${config.orderExpireMinutes}m`,
  });
}

function canonicalize(params) {
  return Object.entries(params)
    .filter(([k, v]) => k !== 'sign' && v !== undefined && v !== null && v !== '')
    .sort(([a], [b]) => (a > b ? 1 : -1))
    .map(([k, v]) => `${k}=${v}`)
    .join('&');
}

function buildAppPayOrderString(order) {
  const params = {
    app_id: config.alipay.appId,
    method: 'alipay.trade.app.pay',
    format: 'JSON',
    charset: 'utf-8',
    sign_type: 'RSA2',
    timestamp: dayjs().format('YYYY-MM-DD HH:mm:ss'),
    version: '1.0',
    notify_url: `${config.callbackBaseUrl}${config.alipay.notifyPath}`,
    biz_content: stringifyBizContent(order),
  };
  const toSign = canonicalize(params);
  const sign = rsaSignSha256(toSign, config.alipay.privateKey);
  const withSign = { ...params, sign };
  const search = new URLSearchParams(withSign);
  return search.toString();
}

function verifyNotifyForm(params) {
  const sign = params.sign;
  if (!sign) return false;
  const toVerify = canonicalize(params);
  return rsaVerifySha256(toVerify, sign, config.alipay.alipayPublicKey);
}

module.exports = {
  buildAppPayOrderString,
  verifyNotifyForm,
};
