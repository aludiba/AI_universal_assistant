# 支付系统说明文档（微信/支付宝 + 宝塔部署）

本文档对应当前项目：

- Flutter 客户端：`ai_writing_cat_flutter`
- 支付后端：`payment_backend`

适用目标：Android 端会员订阅与字数包购买（微信/支付宝），服务端完成下单、回调验签、幂等入账、权益发放。

---

## 1. 支付逻辑总流程

### 1.1 客户端流程（Flutter）

1. 用户在会员页或字数包页选择商品与支付渠道（微信/支付宝）。
2. Flutter 调用后端 `POST /v1/billing/order` 创建订单。
3. 后端返回支付参数：
   - 支付宝：`orderString`
   - 微信：`appId/partnerId/prepayId/packageValue/nonceStr/timestamp/sign`
4. Flutter 拉起对应 SDK 支付。
5. Flutter 轮询订单状态 `GET /v1/billing/order/:orderId?userId=...`。
6. 后端收到支付平台异步回调并验签，订单置为 `PAID`，发放权益（会员或字数）。
7. Flutter 调用 `GET /v1/billing/state/:userId` 同步会员与字数钱包到本地。

### 1.2 服务端流程（核心）

1. 创建订单（`CREATED`）
2. 支付宝/微信发起支付
3. 回调验签
4. 事务内幂等结算：
   - 更新 `payment_orders` 状态为 `PAID`
   - 会员产品：更新 `user_memberships` + 赠送字数
   - 字数包产品：更新 `user_word_wallets` + 生成 `user_word_lots`
5. 客户端查询状态并同步本地

---

## 2. 服务端文件清单（当前版本）

根目录：`payment_backend`

- `package.json`：启动、迁移脚本
- `.env.example`：环境变量模板
- `README.md`：通用说明
- `DEPLOY_BAOTA.md`：本文件
- `Dockerfile` / `docker-compose.yml`：容器部署

业务目录：`src/`

- `src/server.js`
  - 应用入口
  - 安全头校验（可选）
  - 原始 body 读取（支付回调验签需要）
  - 路由挂载
- `src/config.js`
  - 环境变量读取与必填项校验
- `src/db.js`
  - PostgreSQL 连接池
  - Redis（可选）
  - 事务封装 `withTx`
- `src/plans.js`
  - SKU 与价格/权益映射（会员 + 字数包）
- `src/routes/billing.js`
  - 订单创建、订单查询、用户权益状态
  - 支付宝/微信回调入口
- `src/services/orderService.js`
  - 创建订单
  - 幂等结算
  - 发放会员与字数权益
  - 订单状态查询、用户账务状态
- `src/providers/alipay.js`
  - 支付宝下单参数（RSA2签名）
  - 回调验签
- `src/providers/wechat.js`
  - 微信 APP 下单（v3）
  - 回调签名校验
  - AES-GCM 解密回调密文
- `src/utils/crypto.js`
  - SHA256 / RSA 签名验签 / AES 解密工具
- `src/scripts/migrate.js`
  - 运行 SQL 迁移脚本

数据库迁移：`migrations/001_init.sql`

- `payment_orders`
- `user_memberships`
- `user_word_wallets`
- `user_word_lots`

---

## 3. API 一览

### 3.1 创建订单

- `POST /v1/billing/order`
- 请求体：

```json
{
  "userId": "u_xxx",
  "sku": "membership.monthly",
  "channel": "wechat"
}
```

### 3.2 查询订单

- `GET /v1/billing/order/:orderId?userId=u_xxx`

### 3.3 查询用户权益状态

- `GET /v1/billing/state/:userId`

### 3.4 支付回调

- 支付宝：`POST /v1/billing/alipay/notify`
- 微信：`POST /v1/billing/wechat/notify`

---

## 4. 宝塔部署方式（按你当前目录风格）

你截图里当前目录是：

- `/www/wwwroot/ai-server`
- 里边有 `server.js`、`package.json`、`ecosystem.config.js` 等

建议保持这个目录，直接替换成新后端结构，步骤如下。

### 4.1 上传文件

把本地 `payment_backend` 全目录上传到服务器，例如：

- `/www/wwwroot/ai-server/payment_backend`

或直接平铺到：

- `/www/wwwroot/ai-server`

> 推荐保留子目录 `payment_backend`，便于和旧文件隔离。

### 4.2 安装依赖

在宝塔终端执行（以子目录方案为例）：

```bash
cd /www/wwwroot/ai-server/payment_backend
npm ci --omit=dev
```

### 4.3 配置环境变量

```bash
cp .env.example .env
```

编辑 `.env`，至少填：

- `POSTGRES_URL`
- `CALLBACK_BASE_URL`
- 支付宝：`ALIPAY_APP_ID / ALIPAY_PRIVATE_KEY / ALIPAY_PUBLIC_KEY`
- 微信：`WECHAT_APP_ID / WECHAT_MCH_ID / WECHAT_SERIAL_NO / WECHAT_PRIVATE_KEY / WECHAT_PLATFORM_PUBLIC_KEY / WECHAT_API_V3_KEY`

> RSA 密钥请用 `\n` 形式存储（不要直接换行）。

### 4.4 初始化数据库

```bash
npm run migrate
```

### 4.5 启动服务（PM2）

#### 方式A：直接命令

```bash
pm2 start src/server.js --name ai-billing
pm2 save
pm2 startup
```

#### 方式B：ecosystem.config.js

在 `payment_backend` 下创建或修改：

```js
module.exports = {
  apps: [
    {
      name: 'ai-billing',
      script: 'src/server.js',
      cwd: '/www/wwwroot/ai-server/payment_backend',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production'
      }
    }
  ]
}
```

启动：

```bash
pm2 start ecosystem.config.js
pm2 save
```

### 4.6 Nginx 反代

把域名（例如 `api.hujiaofenwritingcat.top`）反代到后端端口（默认 `8080`）：

```nginx
location /v1/billing/ {
  proxy_pass http://127.0.0.1:8080;
  proxy_set_header Host $host;
  proxy_set_header X-Real-IP $remote_addr;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto $scheme;
}
```

并确保支付回调地址可公网访问：

- `https://你的域名/v1/billing/alipay/notify`
- `https://你的域名/v1/billing/wechat/notify`

---

## 5. Flutter 端对应配置

文件：`ai_writing_cat_flutter/lib/config/app_config.dart`

重点项：

- `billingBaseUrl`：改成你的后端域名
- `billingApiPath`：默认 `/v1/billing`
- `billingAppToken`：与后端 `APP_CLIENT_TOKEN` 对齐（如启用）
- `wechatAppId`：微信开放平台 AppID

---

## 6. 上线前检查清单（生产必做）

1. **回调验签可用**  
   - 支付宝签名验签通过
   - 微信签名 + 解密通过
2. **幂等性验证**  
   - 重复回调不会重复发放权益
3. **订单状态流转**  
   - CREATED -> PAID 正常
4. **权益核对**  
   - 会员时长正确
   - 字数包数量正确
5. **监控与日志**  
   - PM2 日志正常
   - Nginx access/error 正常
6. **安全**  
   - HTTPS
   - `.env` 不入库
   - 限制管理端口访问

---

## 7. 常见问题排查

### 7.1 Flutter 端支付成功但未开通

- 先查订单接口状态是否 `PAID`
- 若不是，重点看支付回调日志是否进站、是否验签失败

### 7.2 微信回调解密失败

- 检查 `WECHAT_API_V3_KEY` 长度和内容
- 检查平台证书公钥是否最新

### 7.3 支付宝回调验签失败

- 检查 `ALIPAY_PUBLIC_KEY` 是否是支付宝平台公钥
- 检查参数签名串是否被网关改写

---

如果你愿意，我下一步可以再给你一份“**宝塔一键部署命令版**”（按你的服务器目录直接可复制粘贴执行）。

---

## 8. 宝塔一键部署命令版（按你当前目录）

以下命令假设你当前 AI 服务目录是：

- `/www/wwwroot/ai-server`

并采用“同目录下子目录部署”：

- 现有 DeepSeek：`/www/wwwroot/ai-server`（或其子目录）
- 新支付后端：`/www/wwwroot/ai-server/payment_backend`

### 8.1 上传代码后执行（SSH）

```bash
cd /www/wwwroot/ai-server
mkdir -p payment_backend
# 将本地 payment_backend 目录内容上传到这里（宝塔文件管理器上传）
cd /www/wwwroot/ai-server/payment_backend
npm ci --omit=dev
cp .env.example .env
```

编辑 `.env` 填写实际值（必须）：

```bash
vim /www/wwwroot/ai-server/payment_backend/.env
```

### 8.2 初始化数据库

```bash
cd /www/wwwroot/ai-server/payment_backend
npm run migrate
```

### 8.3 启动 PM2 进程

```bash
cd /www/wwwroot/ai-server/payment_backend
pm2 start src/server.js --name ai-billing
pm2 save
pm2 startup
```

查看状态：

```bash
pm2 ls
pm2 logs ai-billing --lines 200
```

### 8.4 Nginx 反向代理（宝塔站点配置）

在你当前对外域名站点的 Nginx 配置追加：

```nginx
location /v1/billing/ {
  proxy_pass http://127.0.0.1:8080;
  proxy_http_version 1.1;
  proxy_set_header Host $host;
  proxy_set_header X-Real-IP $remote_addr;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto $scheme;
}
```

你原有 DeepSeek 代理保持不变（例如 `/ai` -> 原服务端口）。

重载 Nginx：

```bash
nginx -t && nginx -s reload
```

### 8.5 快速自检

```bash
curl -sS http://127.0.0.1:8080/health
curl -sS https://你的域名/v1/billing/state/test_user
```

### 8.6 Flutter 配置同步

确保 `ai_writing_cat_flutter/lib/config/app_config.dart`：

- `billingBaseUrl` = 你的域名（例如 `https://api.xxx.com`）
- `billingApiPath` = `/v1/billing`
- `billingAppToken` 与后端 `APP_CLIENT_TOKEN` 一致（若启用）
- `wechatAppId` 填真实值

### 8.7 回滚命令（需要时）

```bash
pm2 stop ai-billing
pm2 delete ai-billing
# 恢复 nginx 配置后 reload
nginx -t && nginx -s reload
```

---

## 9. 同一个域名部署（你当前宝塔配置对应）

你当前主站点为：

- `api.hujiaofenwritingcat.top`

并且站点配置已包含：

```nginx
include /www/server/panel/vhost/nginx/proxy/api.hujiaofenwritingcat.top/*.conf;
```

因此推荐做法是：**不要改主 `server {}`，只在 proxy include 目录新增两个反代文件**。

### 9.1 新增 AI 反代文件

文件路径：

- `/www/server/panel/vhost/nginx/proxy/api.hujiaofenwritingcat.top/00_ai.conf`

内容：

```nginx
# DeepSeek 代理（同域名 /ai）— 流式 SSE 优化
location = /ai {
    proxy_pass http://127.0.0.1:3000;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    # 禁用所有缓冲，逐块透传 SSE 流
    proxy_buffering off;
    proxy_cache off;
    chunked_transfer_encoding on;
    tcp_nodelay on;
    proxy_read_timeout 600s;
    proxy_send_timeout 600s;
}

location ^~ /ai/ {
    proxy_pass http://127.0.0.1:3000;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    proxy_buffering off;
    proxy_cache off;
    chunked_transfer_encoding on;
    tcp_nodelay on;
    proxy_read_timeout 600s;
    proxy_send_timeout 600s;
}
```

> `3000` 是示例端口，请替换为你当前 DeepSeek 后端实际监听端口。

### 9.2 新增支付反代文件

文件路径：

- `/www/server/panel/vhost/nginx/proxy/api.hujiaofenwritingcat.top/01_billing.conf`

内容：

```nginx
# 支付后端（同域名 /v1/billing）
location ^~ /v1/billing/ {
    proxy_pass http://127.0.0.1:8080;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_read_timeout 120s;
    proxy_send_timeout 120s;
}
```

### 9.3 一键写入这两个 conf（可直接执行）

```bash
cat >/www/server/panel/vhost/nginx/proxy/api.hujiaofenwritingcat.top/00_ai.conf <<'EOF'
location = /ai {
    proxy_pass http://127.0.0.1:3000;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_buffering off;
    proxy_cache off;
    chunked_transfer_encoding on;
    tcp_nodelay on;
    proxy_read_timeout 600s;
    proxy_send_timeout 600s;
}

location ^~ /ai/ {
    proxy_pass http://127.0.0.1:3000;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_buffering off;
    proxy_cache off;
    chunked_transfer_encoding on;
    tcp_nodelay on;
    proxy_read_timeout 600s;
    proxy_send_timeout 600s;
}
EOF

cat >/www/server/panel/vhost/nginx/proxy/api.hujiaofenwritingcat.top/01_billing.conf <<'EOF'
location ^~ /v1/billing/ {
    proxy_pass http://127.0.0.1:8080;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_read_timeout 120s;
    proxy_send_timeout 120s;
}
EOF

nginx -t && nginx -s reload
```

### 9.4 同域名下后端与 Flutter 必配项

后端 `.env`：

```env
CALLBACK_BASE_URL=https://api.hujiaofenwritingcat.top
ALIPAY_NOTIFY_PATH=/v1/billing/alipay/notify
WECHAT_NOTIFY_PATH=/v1/billing/wechat/notify
```

Flutter `lib/config/app_config.dart`：

- `aiProxyUrl = 'https://api.hujiaofenwritingcat.top/ai'`
- `billingBaseUrl = 'https://api.hujiaofenwritingcat.top'`
- `billingApiPath = '/v1/billing'`

### 9.5 最终检查命令

```bash
nginx -t && nginx -s reload
pm2 ls
pm2 logs ai-billing --lines 100
curl -sS https://api.hujiaofenwritingcat.top/v1/billing/state/test_user
```

### 9.6 宝塔面板操作版（不走终端）

如果你希望全程在宝塔 UI 操作，可按以下步骤创建同域名反代规则：

1. 左侧菜单进入 `文件`
2. 打开目录：
   - `/www/server/panel/vhost/nginx/proxy/api.hujiaofenwritingcat.top/`
3. 新建文件 `00_ai.conf`，写入（按实际 AI 端口修改）：

```nginx
location = /ai {
    proxy_pass http://127.0.0.1:3000;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_buffering off;
    proxy_cache off;
    chunked_transfer_encoding on;
    tcp_nodelay on;
    proxy_read_timeout 600s;
    proxy_send_timeout 600s;
}

location ^~ /ai/ {
    proxy_pass http://127.0.0.1:3000;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_buffering off;
    proxy_cache off;
    chunked_transfer_encoding on;
    tcp_nodelay on;
    proxy_read_timeout 600s;
    proxy_send_timeout 600s;
}
```

4. 新建文件 `01_billing.conf`，写入：

```nginx
location ^~ /v1/billing/ {
    proxy_pass http://127.0.0.1:8080;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_read_timeout 120s;
    proxy_send_timeout 120s;
}
```

5. 进入 `网站 -> api.hujiaofenwritingcat.top -> 设置 -> 配置文件`，确认包含：

```nginx
include /www/server/panel/vhost/nginx/proxy/api.hujiaofenwritingcat.top/*.conf;
```

6. 点击“保存并重载”（或“重载配置”）
7. 在宝塔终端或本地执行校验：

```bash
curl -sS https://api.hujiaofenwritingcat.top/ai
curl -sS https://api.hujiaofenwritingcat.top/v1/billing/state/test_user
```

如返回异常，优先检查：

- AI 服务实际监听端口是否为 `3000`
- 支付服务是否已由 PM2 启动并监听 `8080`
- Nginx 配置是否有其他 `location` 覆盖了 `/ai` 或 `/v1/billing/`
