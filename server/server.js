const express = require("express");
const http = require("http");
const WebSocket = require("ws");

const app = express();
app.use(express.json());

const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

const latestTicks = {};   // { SYMBOL: {type,symbol,bid,ask,mid,time} }
const latestSignals = {}; // { "SYMBOL|TF": {symbol, tf, signal, time, meta} }
const latestCandles = {}; // { "SYMBOL|TF": {symbol, tf, time, o,h,l,c} }

let lastTickAt = null;

function broadcast(obj) {
  const msg = JSON.stringify(obj);
  for (const c of wss.clients) {
    if (c.readyState === WebSocket.OPEN) c.send(msg);
  }
}

// tiny request log
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

app.get("/health", (req, res) => {
  res.json({
    ok: true,
    uptimeSec: Math.round(process.uptime()),
    ticksCount: Object.keys(latestTicks).length,
    lastTickAt,
    signalsCount: Object.keys(latestSignals).length,
    serverTime: new Date().toISOString(),
  });
});

app.post("/tick", (req, res) => {
  const { symbol, bid, ask, time } = req.body || {};
  if (!symbol || bid === undefined || ask === undefined) {
    console.log("BAD /tick body:", req.body);
    return res.status(400).json({ error: "Missing fields: symbol,bid,ask" });
  }

  const tick = {
    type: "tick",
    symbol: String(symbol).toUpperCase(),
    bid: Number(bid),
    ask: Number(ask),
    mid: (Number(bid) + Number(ask)) / 2.0,
    time: time || new Date().toISOString(),
  };

  latestTicks[tick.symbol] = tick;
  lastTickAt = tick.time;

  // broadcast to Flutter
  broadcast(tick);

  return res.json({ ok: true });
});

app.get("/snapshot", (req, res) => {
  res.json({ ticks: latestTicks });
});

// Signals: your model can POST here (from python or from flutter backend)
app.post("/signal", (req, res) => {
  const { symbol, tf, signal, time, meta } = req.body || {};
  if (!symbol || !tf || !signal) {
    return res.status(400).json({ error: "Missing fields: symbol, tf, signal" });
  }

  const key = `${String(symbol).toUpperCase()}|${String(tf)}`;
  const obj = {
    type: "signal",
    symbol: String(symbol).toUpperCase(),
    tf: String(tf),
    signal: String(signal),          // e.g. BUY/SELL/WAIT
    time: time || new Date().toISOString(),
    meta: meta || null,              // optional extra info (confidence, sl/tp, etc.)
  };

  latestSignals[key] = obj;

  // broadcast so the app can update instantly
  broadcast(obj);

  return res.json({ ok: true });
});

app.get("/signals", (req, res) => {
  res.json({ signals: latestSignals });
});

// Optional candles route (if you move to OHLC later)
app.post("/candle", (req, res) => {
  const { symbol, tf, time, open, high, low, close } = req.body || {};
  if (!symbol || !tf || !time || open === undefined || high === undefined || low === undefined || close === undefined) {
    return res.status(400).json({ error: "Missing fields: symbol,tf,time,open,high,low,close" });
  }

  const key = `${String(symbol).toUpperCase()}|${String(tf)}`;
  const candle = {
    type: "candle",
    symbol: String(symbol).toUpperCase(),
    tf: String(tf),
    time: String(time),
    open: Number(open),
    high: Number(high),
    low: Number(low),
    close: Number(close),
  };

  latestCandles[key] = candle;
  broadcast(candle);
  return res.json({ ok: true });
});

const PORT = process.env.PORT || 8080;
server.listen(PORT, "0.0.0.0", () => {
  console.log("Tick/Signal server listening on", PORT);
});
