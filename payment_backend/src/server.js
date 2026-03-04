const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const pino = require('pino');
const pinoHttp = require('pino-http');
const { billingRouter } = require('./routes/billing');
const { config } = require('./config');
const { pool, redis } = require('./db');

const logger = pino({ level: config.logLevel });
const app = express();

app.disable('x-powered-by');
app.use(helmet());
app.use(cors({ origin: true, credentials: false }));
app.use(
  pinoHttp({
    logger,
  }),
);

app.use((req, res, next) => {
  if (!config.appIdHeaderToken) return next();
  if (req.path.includes('/notify')) return next();
  const incoming = req.headers['x-aiua-app-token'];
  if (incoming !== config.appIdHeaderToken) {
    return res.status(401).json({ ok: false, error: 'unauthorized' });
  }
  return next();
});

app.use((req, res, next) => {
  let raw = '';
  req.setEncoding('utf8');
  req.on('data', (chunk) => {
    raw += chunk;
  });
  req.on('end', () => {
    req.rawBodyString = raw;
    if (req.path.endsWith('/alipay/notify')) {
      req.body = Object.fromEntries(new URLSearchParams(raw).entries());
    } else if (raw) {
      try {
        req.body = JSON.parse(raw);
      } catch (_) {
        req.body = {};
      }
    } else {
      req.body = {};
    }
    next();
  });
});

app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    if (redis) {
      await redis.connect().catch(() => {});
      await redis.ping();
    }
    return res.json({ ok: true, env: config.env });
  } catch (error) {
    req.log.error({ err: error }, 'health failed');
    return res.status(500).json({ ok: false });
  }
});

app.use('/v1/billing', billingRouter);

app.use((error, req, res, _next) => {
  req.log.error({ err: error }, 'unhandled error');
  res.status(500).json({ ok: false, error: 'internal_error' });
});

app.listen(config.port, () => {
  logger.info({ port: config.port }, 'billing backend started');
});
