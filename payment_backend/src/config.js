const dotenv = require('dotenv');

dotenv.config();

function required(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required env: ${name}`);
  }
  return value;
}

const config = {
  env: process.env.NODE_ENV || 'development',
  port: Number(process.env.PORT || 8080),
  logLevel: process.env.LOG_LEVEL || 'info',
  apiSignSecret: process.env.API_SIGN_SECRET || '',
  postgresUrl: required('POSTGRES_URL'),
  redisUrl: process.env.REDIS_URL || '',
  callbackBaseUrl: required('CALLBACK_BASE_URL'),
  appIdHeaderToken: process.env.APP_CLIENT_TOKEN || '',
  orderExpireMinutes: Number(process.env.ORDER_EXPIRE_MINUTES || 30),
  membershipSyncGraceSeconds: Number(process.env.MEMBERSHIP_SYNC_GRACE_SECONDS || 8),

  alipay: {
    appId: required('ALIPAY_APP_ID'),
    privateKey: required('ALIPAY_PRIVATE_KEY'),
    alipayPublicKey: required('ALIPAY_PUBLIC_KEY'),
    gateway: process.env.ALIPAY_GATEWAY || 'https://openapi.alipay.com/gateway.do',
    notifyPath: process.env.ALIPAY_NOTIFY_PATH || '/v1/billing/alipay/notify',
  },

  wechat: {
    appId: required('WECHAT_APP_ID'),
    mchId: required('WECHAT_MCH_ID'),
    serialNo: required('WECHAT_SERIAL_NO'),
    privateKey: required('WECHAT_PRIVATE_KEY'),
    platformPublicKey: required('WECHAT_PLATFORM_PUBLIC_KEY'),
    apiV3Key: required('WECHAT_API_V3_KEY'),
    notifyPath: process.env.WECHAT_NOTIFY_PATH || '/v1/billing/wechat/notify',
    gateway: process.env.WECHAT_GATEWAY || 'https://api.mch.weixin.qq.com',
  },
};

module.exports = { config };
