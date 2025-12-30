/**
 * Tawaqu3 Local WS Server (dev)
 * - WebSocket on ws://127.0.0.1:8080
 * - HTTP health: http://127.0.0.1:8080/health
 * - Broadcasts mock ticks for: EURUSD_, XAUUSD_, BTCUSD, ETHUSD
 * - Responds to:
 *    {type:"get_candles", symbol:"XAUUSD", tf:"15m", limit:200}
 *   with:
 *    {type:"candles", symbol:"XAUUSD", tf:"15m", candles:[...]}
 */
const http = require("http");
const { WebSocketServer } = require("ws");
const url = require("url");

const PORT = process.env.PORT ? Number(process.env.PORT) : 8080;

// Keep your underscore symbols (MT5 style)
// Added XAGUSD_ (silver) because your app focuses on gold & silver.
const SYMBOLS = ["EURUSD_", "XAUUSD_", "XAGUSD_", "BTCUSD", "ETHUSD"];

// Client subscriptions (optional)
const clientSubs = new WeakMap(); // ws -> Set(symbols)

// Price state
const base = {
  "EURUSD_": 1.0900,
  "XAUUSD_": 2050.0,
  "XAGUSD_": 24.0,
  "BTCUSD": 43000.0,
  "ETHUSD": 2300.0,
};

const prices = {};
const open24h = {}; // pseudo "24h open" for change%
for (const s of SYMBOLS) {
  prices[s] = base[s] ?? 100.0;
  open24h[s] = prices[s];
}

function canon(sym) {
  // Accept XAUUSD or XAUUSD_ -> map to XAUUSD_
  if (!sym) return "";
  const up = String(sym).toUpperCase();
  // if user passes without underscore but we have underscore version, map it
  if (SYMBOLS.includes(up)) return up;
  if (SYMBOLS.includes(up + "_")) return up + "_";
  return up;
}

function tfSeconds(tf) {
  const s = String(tf || "15m").toLowerCase();
  if (s === "1m") return 60;
  if (s === "5m") return 300;
  if (s === "15m") return 900;
  if (s === "1h") return 3600;
  if (s === "4h") return 14400;
  if (s === "1d") return 86400;
  return 900;
}

// Candle store: key -> array
// key = SYMBOL|TF
const candles = new Map();

function key(sym, tf) {
  return `${canon(sym)}|${String(tf).toLowerCase()}`;
}

function floorToTf(tsMs, tf) {
  const sec = tfSeconds(tf);
  return Math.floor(tsMs / 1000 / sec) * sec * 1000;
}

function pushTick(sym, price) {
  const now = Date.now();
  const change = ((price - open24h[sym]) / open24h[sym]) * 100.0;

  // Provide bid/ask/mid as well (some older Flutter code expects them)
  let spread = 0.0001;
  if (sym === "XAUUSD_") spread = 0.3;
  if (sym === "XAGUSD_") spread = 0.02;
  if (sym === "BTCUSD") spread = 2.0;
  if (sym === "ETHUSD") spread = 0.3;
  const bid = price - spread / 2;
  const ask = price + spread / 2;
  const mid = price;

  // Broadcast tick
  const tickMsg = JSON.stringify({
    type: "tick",
    symbol: sym,
    price: mid,
    mid,
    bid,
    ask,
    change24h: Number.isFinite(change) ? change : null,
    time: new Date(now).toISOString(),
  });

  for (const ws of wss.clients) {
    if (ws.readyState !== 1) continue;

    // If client subscribed, filter
    const subs = clientSubs.get(ws);
    if (subs && subs.size > 0 && !subs.has(sym)) continue;

    ws.send(tickMsg);
  }

  // Update candles for all supported TFs
  const tfs = ["1m", "5m", "15m", "1h"];
  for (const tf of tfs) {
    const k = key(sym, tf);
    const start = floorToTf(now, tf);
    const list = candles.get(k) ?? [];
    const last = list.length ? list[list.length - 1] : null;

    if (!last || last.startTime !== start) {
      // new candle
      const c = {
        startTime: start,
        time: new Date(start).toISOString(),
        open: price,
        high: price,
        low: price,
        close: price,
      };
      list.push(c);
      // cap
      while (list.length > 600) list.shift();
      candles.set(k, list);
    } else {
      // update current candle
      last.high = Math.max(last.high, price);
      last.low = Math.min(last.low, price);
      last.close = price;
    }
  }
}

function randomWalk(sym) {
  const p = prices[sym];
  // small deltas based on symbol
  let scale = 0.0004;
  if (sym === "XAUUSD_") scale = 0.8;
  if (sym === "XAGUSD_") scale = 0.05;
  if (sym === "BTCUSD") scale = 25.0;
  if (sym === "ETHUSD") scale = 2.5;

  const delta = (Math.random() - 0.5) * 2 * scale;
  let next = p + delta;

  // clamp
  if (sym === "EURUSD_") next = Math.max(0.6, Math.min(2.0, next));
  if (sym === "XAUUSD_") next = Math.max(900, Math.min(3500, next));
  if (sym === "XAGUSD_") next = Math.max(8, Math.min(80, next));
  if (sym === "BTCUSD") next = Math.max(1000, Math.min(200000, next));
  if (sym === "ETHUSD") next = Math.max(50, Math.min(20000, next));

  prices[sym] = next;
  pushTick(sym, next);
}

// HTTP server (health)
const server = http.createServer((req, res) => {
  const parsed = url.parse(req.url, true);
  if (parsed.pathname === "/health") {
    const payload = {
      ok: true,
      port: PORT,
      time: new Date().toISOString(),
      clients: wss.clients.size,
      symbols: SYMBOLS,
      candlesKeys: candles.size,
      uptimeSec: Math.floor(process.uptime()),
    };
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify(payload));
    return;
  }
  res.writeHead(200, { "Content-Type": "text/plain" });
  res.end("Tawaqu3 WS Server running. Use /health for JSON.");
});

// WS server
const wss = new WebSocketServer({ server });

wss.on("connection", (ws) => {
  console.log("WS client connected");
  clientSubs.set(ws, new Set());

  ws.on("message", (buf) => {
    let msg;
    try {
      msg = JSON.parse(buf.toString());
    } catch {
      return;
    }

    const type = String(msg.type || "").toLowerCase();

    if (type === "subscribe") {
      const sym = canon(msg.symbol);
      if (!sym) return;
      const subs = clientSubs.get(ws);
      subs.add(sym);
      ws.send(JSON.stringify({ type: "subscribed", symbol: sym }));
      return;
    }

    if (type === "unsubscribe") {
      const sym = canon(msg.symbol);
      const subs = clientSubs.get(ws);
      subs.delete(sym);
      ws.send(JSON.stringify({ type: "unsubscribed", symbol: sym }));
      return;
    }

    if (type === "get_candles") {
      const symReq = String(msg.symbol || "");
      const tf = String(msg.tf || "15m").toLowerCase();
      const limit = Math.max(10, Math.min(600, Number(msg.limit || 200)));

      const sym = canon(symReq);
      const k = key(sym, tf);
      const list = candles.get(k) ?? [];

      const slice = list.slice(Math.max(0, list.length - limit));
      ws.send(JSON.stringify({
        type: "candles",
        symbol: symReq, // keep same string the client asked for
        tf,
        candles: slice.map(c => ({
          time: c.time,
          open: c.open,
          high: c.high,
          low: c.low,
          close: c.close,
        })),
      }));
      return;
    }
  });

  ws.on("close", () => console.log("WS client disconnected"));
  ws.on("error", (e) => console.log("WS error:", e.message));
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`Tawaqu3 WS server listening on ws://127.0.0.1:${PORT}`);
  console.log(`Health: http://127.0.0.1:${PORT}/health`);
});

// start ticks
setInterval(() => {
  for (const s of SYMBOLS) randomWalk(s);
}, 1000);