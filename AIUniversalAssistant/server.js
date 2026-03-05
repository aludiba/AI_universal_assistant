const express = require("express");
const crypto = require("crypto");
const fetch = (...args) =>
  import("node-fetch").then(({ default: fetchFn }) => fetchFn(...args));

const app = express();
app.disable("x-powered-by");
app.set("trust proxy", true);

const PORT = process.env.PORT || 3000;
const DEEPSEEK_KEY = process.env.DEEPSEEK_KEY;
const DEEPSEEK_URL = "https://api.deepseek.com/v1/chat/completions";
const AI_BODY_LIMIT = process.env.AI_BODY_LIMIT || "512kb";
const APP_CLIENT_TOKEN = process.env.APP_CLIENT_TOKEN || "";
const RATE_LIMIT_WINDOW_MS = Number(process.env.RATE_LIMIT_WINDOW_MS || 60_000);
const RATE_LIMIT_MAX = Number(process.env.RATE_LIMIT_MAX || 30);
// 上游 DeepSeek 等待超时（毫秒），流式/长文生成建议 120s+，可通过 UPSTREAM_TIMEOUT_MS 覆盖
const UPSTREAM_TIMEOUT_MS = Number(process.env.UPSTREAM_TIMEOUT_MS || 120_000);
const APP_SIGNING_SECRET = process.env.APP_SIGNING_SECRET || "";
const SIGN_MAX_SKEW_SEC = Number(process.env.SIGN_MAX_SKEW_SEC || 300);

const aiJsonParser = express.json({ limit: AI_BODY_LIMIT });
const rateStore = new Map();

function getClientIp(req) {
  const forwarded = req.headers["x-forwarded-for"];
  if (typeof forwarded === "string" && forwarded.length > 0) {
    return forwarded.split(",")[0].trim();
  }
  return req.ip || req.socket?.remoteAddress || "unknown";
}

function isRateLimited(ip) {
  const now = Date.now();
  const record = rateStore.get(ip);
  if (!record || now > record.resetAt) {
    rateStore.set(ip, { count: 1, resetAt: now + RATE_LIMIT_WINDOW_MS });
    return false;
  }
  record.count += 1;
  return record.count > RATE_LIMIT_MAX;
}

setInterval(() => {
  const now = Date.now();
  for (const [ip, record] of rateStore.entries()) {
    if (now > record.resetAt) {
      rateStore.delete(ip);
    }
  }
}, Math.max(30_000, RATE_LIMIT_WINDOW_MS)).unref();

function sha256Hex(input) {
  return crypto.createHash("sha256").update(input, "utf8").digest("hex");
}

function safeEqualHex(a, b) {
  if (typeof a !== "string" || typeof b !== "string") return false;
  if (a.length !== b.length) return false;
  try {
    const ba = Buffer.from(a, "hex");
    const bb = Buffer.from(b, "hex");
    if (ba.length !== bb.length || ba.length === 0) return false;
    return crypto.timingSafeEqual(ba, bb);
  } catch (_e) {
    return false;
  }
}

app.get("/", (_req, res) => {
  res.send("AI Server is running 🚀");
});

app.post("/ai", aiJsonParser, async (req, res) => {
  if (!DEEPSEEK_KEY) {
    return res.status(500).json({ error: "missing DEEPSEEK_KEY" });
  }

  const clientIp = getClientIp(req);
  if (isRateLimited(clientIp)) {
    return res.status(429).json({ error: "too_many_requests" });
  }

  // 可选来源校验：配置 APP_CLIENT_TOKEN 后，客户端必须携带 x-aiua-app-token
  if (APP_CLIENT_TOKEN) {
    const token = req.headers["x-aiua-app-token"];
    if (token !== APP_CLIENT_TOKEN) {
      return res.status(401).json({ error: "unauthorized" });
    }
  }

  // 版本 + 时间戳签名校验（可选）
  if (APP_SIGNING_SECRET) {
    const appVersion = req.headers["x-aiua-app-version"];
    const tsHeader = req.headers["x-aiua-ts"];
    const signHeader = req.headers["x-aiua-sign"];
    if (!appVersion || !tsHeader || !signHeader) {
      return res.status(401).json({ error: "missing_signature_headers" });
    }

    const ts = Number(tsHeader);
    if (!Number.isFinite(ts)) {
      return res.status(401).json({ error: "invalid_signature_timestamp" });
    }

    const nowSec = Math.floor(Date.now() / 1000);
    if (Math.abs(nowSec - ts) > SIGN_MAX_SKEW_SEC) {
      return res.status(401).json({ error: "signature_expired" });
    }

    const path = "/ai";
    const expected = sha256Hex(`${appVersion}.${ts}.${path}.${APP_SIGNING_SECRET}`);
    if (!safeEqualHex(String(signHeader), expected)) {
      return res.status(401).json({ error: "invalid_signature" });
    }
  }

  try {
    if (!req.body || typeof req.body !== "object" || Array.isArray(req.body)) {
      return res.status(400).json({ error: "invalid_request_body" });
    }

    const payload = { ...req.body };
    if (!payload.model) {
      payload.model = "deepseek-chat";
    }

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), UPSTREAM_TIMEOUT_MS);

    let upstream;
    try {
      upstream = await fetch(DEEPSEEK_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${DEEPSEEK_KEY}`,
        },
        body: JSON.stringify(payload),
        signal: controller.signal,
      });
    } finally {
      clearTimeout(timeoutId);
    }

    const isStream = payload.stream === true;

    if (isStream) {
      res.status(upstream.status);
      res.setHeader(
        "Content-Type",
        upstream.headers.get("content-type") || "text/event-stream; charset=utf-8"
      );
      res.setHeader("Cache-Control", "no-cache");
      res.setHeader("Connection", "keep-alive");
      // 告诉 Nginx 不要缓冲此响应，逐块透传
      res.setHeader("X-Accel-Buffering", "no");
      // 立即刷出 HTTP 头，让客户端尽早开始接收
      res.flushHeaders();

      if (!upstream.body) {
        return res.end();
      }

      upstream.body.on("error", () => {
        if (!res.headersSent) {
          res.status(502).end();
        } else {
          res.end();
        }
      });

      // 逐块写入并立即 flush，避免 Node.js 内部缓冲合并小块
      upstream.body.on("data", (chunk) => {
        res.write(chunk);
        if (typeof res.flush === "function") res.flush();
      });
      upstream.body.on("end", () => {
        res.end();
      });
      return;
    }

    const text = await upstream.text();
    let data;
    try {
      data = JSON.parse(text);
    } catch (_e) {
      data = { error: "invalid_upstream_response", raw: text };
    }

    return res.status(upstream.status).json(data);
  } catch (err) {
    if (err && err.name === "AbortError") {
      return res.status(504).json({ error: "upstream_timeout" });
    }
    return res.status(500).json({ error: "server error", detail: String(err) });
  }
});

app.listen(PORT, () => {
  console.log(`AI Server running on ${PORT}`);
});

