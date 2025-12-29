const express = require("express");
const http = require("http");
const WebSocket = require("ws");

const app = express();
app.use(express.json());

const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

const latestTicks = {};      // SYMBOL -> tick
const candleHistory = {};    // "SYMBOL|TF" -> candles[]
const currentCandle = {};    // "SYMBOL|TF" -> current candle

const TF_LIST = ["1m","5m","15m","30m","1h","4h","1d"];

function broadcast(obj) {
  const msg = JSON.stringify(obj);
  for (const c of wss.clients) {
    if (c.readyState === WebSocket.OPEN) c.send(msg);
  }
}

function tfToMs(tf) {
  const s = String(tf).trim().toLowerCase();
  if (s.endsWith("m")) return parseInt(s.slice(0, -1), 10) * 60 * 1000;
  if (s.endsWith("h")) return parseInt(s.slice(0, -1), 10) * 60 * 60 * 1000;
  if (s.endsWith("d")) return parseInt(s.slice(0, -1), 10) * 24 * 60 * 60 * 1000;
  return 60 * 1000;
}

function bucketStartMs(tsMs, tfMs) {
  return Math.floor(tsMs / tfMs) * tfMs;
}

function ensureArr(key) {
  if (!candleHistory[key]) candleHistory[key] = [];
  return candleHistory[key];
}

function upsertCandle(symbol, tf, tsMs, price) {
  const tfMs = tfToMs(tf);
  const key = `${symbol}|${tf}`;
  const bucket = bucketStartMs(tsMs, tfMs);

  const cur = currentCandle[key];
  if (!cur || cur.t !== bucket) {
    if (cur) {
      ensureArr(key).push(cur);
      if (candleHistory[key].length > 600) candleHistory[key].splice(0, candleHistory[key].length - 600);
    }
    currentCandle[key] = { t: bucket, o: price, h: price, l: price, c: price, v: 1 };
    broadcast({ type: "candle", symbol, tf, ...currentCandle[key] });
    return;
  }

  cur.h = Math.max(cur.h, price);
  cur.l = Math.min(cur.l, price);
  cur.c = price;
  cur.v = (cur.v || 0) + 1;

  broadcast({ type: "candle", symbol, tf, ...cur });
}

app.get("/health", (req, res) => {
  res.json({
    ok: true,
    uptimeSec: Math.round(process.uptime()),
    symbols: Object.keys(latestTicks),
    candlesKeys: Object.keys(candleHistory).length,
    serverTime: new Date().toISOString(),
  });
});

app.post("/tick", (req, res) => {
  const { symbol, bid, ask, time } = req.body || {};
  if (!symbol || bid === undefined || ask === undefined) {
    return res.status(400).json({ error: "Missing fields: symbol,bid,ask" });
  }

  const S = String(symbol).toUpperCase();
  const tick = {
    type: "tick",
    symbol: S,
    bid: Number(bid),
    ask: Number(ask),
    mid: (Number(bid) + Number(ask)) / 2.0,
    time: time || new Date().toISOString(),
  };

  latestTicks[S] = tick;
  broadcast(tick);

  const tsMs = Date.parse(tick.time) || Date.now();
  for (const tf of TF_LIST) upsertCandle(S, tf, tsMs, tick.mid);

  res.json({ ok: true });
});

wss.on("connection", (ws) => {
  ws.on("message", (raw) => {
    let msg = null;
    try { msg = JSON.parse(String(raw)); } catch (_) { return; }
    if (!msg || !msg.type) return;

    if (msg.type === "get_candles") {
      const symbol = String(msg.symbol || "").toUpperCase();
      const tf = String(msg.tf || "1m");
      const limit = Math.max(1, Math.min(600, Number(msg.limit || 400)));
      const key = `${symbol}|${tf}`;

      const hist = candleHistory[key] ? candleHistory[key].slice() : [];
      const cur = currentCandle[key] ? [currentCandle[key]] : [];
      const all = hist.concat(cur);
      const out = all.length > limit ? all.slice(all.length - limit) : all;

      ws.send(JSON.stringify({ type: "ohlc", symbol, tf, candles: out }));
    }
  });
});

const PORT = process.env.PORT || 8080;
server.listen(PORT, "0.0.0.0", () => console.log("Server listening on", PORT));
