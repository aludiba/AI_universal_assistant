# Billing Backend (Alipay + WeChat)

Production-oriented billing backend for Flutter app membership subscriptions and word-pack purchases.

## Features

- Create order (`alipay` / `wechat`)
- Alipay app order string generation (RSA2 sign)
- WeChat App unified order (`v3/pay/transactions/app`)
- Callback signature verification and idempotent settlement
- Membership entitlement issuance
- Word wallet issuance
- Order query & user billing state query

## Stack

- Node.js + Express
- PostgreSQL
- Redis (optional, for short lock anti-duplicate callback)

## Quick Start

1. Copy env file:

```bash
cp .env.example .env
```

2. Install dependencies:

```bash
npm install
```

3. Run migrations:

```bash
npm run migrate
```

4. Start service:

```bash
npm start
```

## Important Env Formatting

For RSA keys in `.env`, replace line breaks with `\n`, e.g.

```env
ALIPAY_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----
WECHAT_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----
WECHAT_PLATFORM_PUBLIC_KEY=-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----
```

## API

- `POST /v1/billing/order`
  - body: `{ userId, sku, channel }`
  - returns pay payload:
    - Alipay: `{ orderString }`
    - WeChat: `{ appId, partnerId, prepayId, packageValue, nonceStr, timestamp, sign, signType }`

- `GET /v1/billing/order/:orderId?userId=...`
- `GET /v1/billing/state/:userId`
- `POST /v1/billing/alipay/notify`
- `POST /v1/billing/wechat/notify`

## SKU conventions (default)

- Membership:
  - `membership.lifetime`
  - `membership.yearly`
  - `membership.monthly`
  - `membership.weekly`
- Word packs:
  - `wordpack.500k`
  - `wordpack.2m`
  - `wordpack.6m`

## Deployment Notes

- Use HTTPS.
- Put service behind WAF / API Gateway.
- Lock down callback endpoints to payment-provider IP allowlists if available.
- Rotate keys regularly.
- Add metrics + alerting for callback failure rate and paid-not-settled mismatches.

## Flutter Integration (Android)

Use the same backend host in Flutter config:

- `AppConfig.billingBaseUrl`
- `AppConfig.billingAppToken`
- `AppConfig.wechatAppId`

Then purchase flow is:

1. Flutter calls `POST /v1/billing/order`
2. Flutter launches SDK (`fluwx` / `alipay_kit`)
3. Flutter polls `GET /v1/billing/order/:id`
4. Flutter syncs state via `GET /v1/billing/state/:userId`
