"use strict";

const http = require("http");
const WebSocket = require("ws");
const { URL } = require("url");

const PORT = parseInt(process.env.PORT || "8080", 10);
const MOCK = String(process.env.MOCK || "0") === "1"; // IMPORTANT: set MOCK=0 for real bridge ticks

// -------------------- helpers --------------------
function normSymbol(s) {
  const raw = String(s || "").trim();
  if (!raw) return raw;
  // MT5 broker style: strip ONE trailing underscore
  return raw.endsWith("_") ? raw.slice(0, -1) : raw;
}

function jsonResponse(res, code, obj) {
  res.writeHead(code, { "Content-Type": "application/json" });
  res.end(JSON.stringify(obj));
}

function readJson(req) {
  return new Promise((resolve, reject) => {
    let body = "";
    req.on("data", (c) => (body += c.toString("utf8")));
    req.on("end", () => {
      if (!body) return resolve({});
      try { resolve(JSON.parse(body)); }
      catch (e) { reject(e); }
    });
    req.on("error", reject);
  });
}

function nowIso() {
  return new Date().toISOString();
}

// -------------------- state --------------------
const latestTicks = {};           // sym -> {type:'tick', symbol, bid, ask, mid, time}
const candlesByKey = {};          // `${sym}__${tf}` -> Candle[]
const lastSignals = {};           // `${sym}__${tf}` -> Signal

function key(sym, tf) {
  return `${sym}__${String(tf || "").toLowerCase()}`;
}

function wsBroadcast(msg) {
  const s = JSON.stringify(msg);
  wss.clients.forEach((ws) => {
    if (ws.readyState !== WebSocket.OPEN) return;

    // optional filtering by subscription
    if (ws._subs && ws._subs.size > 0) {
      const sym = msg.symbol ? String(msg.symbol) : "";
      if (sym && !ws._subs.has(sym)) return;
    }

    ws.send(s);
  });
}

function snapshotFor(ws) {
  // send full snapshot or filtered snapshot (if subscribed)
  const snapTicks = {};
  if (ws._subs && ws._subs.size > 0) {
    ws._subs.forEach((sym) => {
      if (latestTicks[sym]) snapTicks[sym] = latestTicks[sym];
    });
  } else {
    Object.assign(snapTicks, latestTicks);
  }

  const snapCandles = {};
  Object.keys(candlesByKey).forEach((k) => {
    const sym = k.split("__")[0];
    if (ws._subs && ws._subs.size > 0 && !ws._subs.has(sym)) return;
    snapCandles[k] = candlesByKey[k];
  });

  const snapSignals = {};
  Object.keys(lastSignals).forEach((k) => {
    const sym = k.split("__")[0];
    if (ws._subs && ws._subs.size > 0 && !ws._subs.has(sym)) return;
    snapSignals[k] = lastSignals[k];
  });

  ws.send(JSON.stringify({
    type: "snapshot",
    time: nowIso(),
    ticks: snapTicks,
    candles: snapCandles,
    signals: snapSignals,
  }));
}

// -------------------- ingest handlers --------------------
function ingestTick(msg) {
  const sym = normSymbol(msg.symbol);
  const bid = Number(msg.bid);
  const ask = Number(msg.ask);
  const time = msg.time ? String(msg.time) : nowIso();

  if (!sym || !Number.isFinite(bid) || !Number.isFinite(ask)) return false;

  const mid = Number.isFinite(Number(msg.mid)) ? Number(msg.mid) : (bid + ask) / 2.0;

  const tickMsg = { type: "tick", symbol: sym, bid, ask, mid, time };
  latestTicks[sym] = tickMsg;
  wsBroadcast(tickMsg);
  return true;
}

function ingestCandle(msg) {
  const sym = normSymbol(msg.symbol);
  const tf = String(msg.tf || "").toLowerCase();
  if (!sym || !tf) return false;

  const candle = {
    type: "candle",
    symbol: sym,
    tf,
    time: msg.time ? String(msg.time) : nowIso(),
    open: Number(msg.open),
    high: Number(msg.high),
    low:  Number(msg.low),
    close:Number(msg.close),
    volume: Number.isFinite(Number(msg.volume)) ? Number(msg.volume) : 0,
  };

  if (![candle.open, candle.high, candle.low, candle.close].every(Number.isFinite)) return false;

  const k = key(sym, tf);
  const arr = candlesByKey[k] || [];
  // keep last ~800
  arr.push({ ...candle, type: undefined }); // store without "type" to keep payload smaller in snapshot
  while (arr.length > 800) arr.shift();
  candlesByKey[k] = arr;

  wsBroadcast({ type: "candle", ...candle });
  return true;
}

function ingestSignal(msg) {
  const sym = normSymbol(msg.symbol);
  const tf = String(msg.tf || "").toLowerCase();
  const signal = String(msg.signal || "");
  if (!sym || !tf || !signal) return false;

  const s = {
    type: "signal",
    symbol: sym,
    tf,
    signal,
    meta: msg.meta || {},
    time: msg.time ? String(msg.time) : nowIso(),
  };

  lastSignals[key(sym, tf)] = s;
  wsBroadcast(s);
  return true;
}

// -------------------- HTTP server --------------------
const server = http.createServer(async (req, res) => {
  try {
    const u = new URL(req.url, `http://${req.headers.host}`);
    const path = u.pathname;

    if (req.method === "GET" && path === "/health") {
      return jsonResponse(res, 200, { ok: true, mock: MOCK, time: nowIso() });
    }

    if (req.method === "POST" && (path === "/tick" || path === "/candle" || path === "/signal")) {
      const body = await readJson(req);

      let ok = false;
      if (path === "/tick") ok = ingestTick(body);
      if (path === "/candle") ok = ingestCandle(body);
      if (path === "/signal") ok = ingestSignal(body);

      return jsonResponse(res, ok ? 200 : 400, { ok });
    }

    jsonResponse(res, 404, { ok: false, error: "Not found" });
  } catch (e) {
    jsonResponse(res, 500, { ok: false, error: String(e) });
  }
});

// -------------------- WebSocket server --------------------
const wss = new WebSocket.Server({ server });

wss.on("connection", (ws) => {
  ws._subs = new Set();

  ws.on("message", (data) => {
    try {
      const m = JSON.parse(data.toString());
      if (m && m.type === "subscribe" && Array.isArray(m.symbols)) {
        ws._subs = new Set(m.symbols.map((x) => normSymbol(String(x))));
        snapshotFor(ws);
      }
    } catch (_) {}
  });

  ws.on("pong", () => (ws.isAlive = true));

  snapshotFor(ws);
});

// ping keepalive
const pingTimer = setInterval(() => {
  wss.clients.forEach((ws) => {
    if (ws.isAlive === false) return ws.terminate();
    ws.isAlive = false;
    ws.ping();
  });
}, 15000);

wss.on("close", () => clearInterval(pingTimer));

// -------------------- MOCK mode (optional) --------------------
if (MOCK) {
  const base = {
    "EURUSD": 1.09,
    "XAUUSD": 2050.0,
    "XAGUSD": 24.0,
    "BTCUSD": 43000.0,
    "ETHUSD": 2300.0,
  };

  Object.keys(base).forEach((s) => {
    const p = base[s];
    latestTicks[s] = { type: "tick", symbol: s, bid: p - 0.01, ask: p + 0.01, mid: p, time: nowIso() };
  });

  setInterval(() => {
    Object.keys(base).forEach((s) => {
      const drift = (Math.random() - 0.5) * (s.includes("USD") ? 2 : 0.002);
      base[s] = Math.max(0.0001, base[s] + drift);
      ingestTick({ symbol: s, bid: base[s] - 0.01, ask: base[s] + 0.01, time: nowIso() });
    });
  }, 300);
}

server.listen(PORT, () => {
  console.log(`[server] http+ws listening on :${PORT} | MOCK=${MOCK ? "1" : "0"}`);
  console.log(`[server] bridge ingest: POST /tick /candle /signal`);
});
