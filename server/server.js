const express = require('express');
const bodyParser = require('body-parser');
const http = require('http');
const WebSocket = require('ws');

const app = express();

// Minimal CORS without extra packages
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  if (req.method === 'OPTIONS') return res.sendStatus(204);
  next();
});

app.use(bodyParser.json());

const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

const latestPrices = {};
const candlesStore = {};   // key = `${symbol}_${tf}` -> candles[]
const latestSignals = {};  // key = `${symbol}_${tf}` -> last signal

function broadcast(obj) {
  const msg = JSON.stringify(obj);
  for (const client of wss.clients) {
    if (client.readyState === WebSocket.OPEN) client.send(msg);
  }
}

// -------- TICKS --------
app.post('/tick', (req, res) => {
  const { symbol, bid, ask, time } = req.body || {};
  if (!symbol || bid === undefined || ask === undefined) {
    return res.status(400).json({ error: 'Missing fields: symbol, bid, ask' });
  }

  const tick = {
    type: 'tick',
    symbol,
    bid: Number(bid),
    ask: Number(ask),
    time: time || new Date().toISOString(),
  };

  latestPrices[symbol] = tick;
  broadcast(tick);
  return res.json({ status: 'ok' });
});

app.get('/snapshot', (req, res) => res.json(latestPrices));

// -------- CANDLES --------
app.post('/candle', (req, res) => {
  const { symbol, tf, time, open, high, low, close } = req.body || {};
  if (!symbol || !tf || !time || open === undefined || high === undefined || low === undefined || close === undefined) {
    return res.status(400).json({ error: 'Missing fields: symbol, tf, time, open, high, low, close' });
  }

  const candle = {
    type: 'candle',
    symbol,
    tf,
    time,
    open: Number(open),
    high: Number(high),
    low: Number(low),
    close: Number(close),
  };

  const key = `${symbol}_${tf}`;
  if (!candlesStore[key]) candlesStore[key] = [];
  candlesStore[key].push(candle);

  // keep last 600 candles
  if (candlesStore[key].length > 600) candlesStore[key] = candlesStore[key].slice(-600);

  broadcast(candle);
  return res.json({ status: 'ok' });
});

app.get('/candles', (req, res) => {
  const symbol = (req.query.symbol || '').toString();
  const tf = (req.query.tf || '').toString();
  const limit = Math.max(1, Math.min(parseInt((req.query.limit || '200').toString(), 10), 600));

  if (!symbol || !tf) return res.status(400).json({ error: 'Missing query: symbol, tf' });

  const key = `${symbol}_${tf}`;
  const arr = candlesStore[key] || [];
  return res.json(arr.slice(-limit));
});

// -------- SIGNALS --------
app.post('/signal', (req, res) => {
  const { symbol, tf, time, output, meta } = req.body || {};
  if (!symbol || !tf || output === undefined) {
    return res.status(400).json({ error: 'Missing fields: symbol, tf, output' });
  }

  const msg = {
    type: 'signal',
    symbol,
    tf,
    time: time || new Date().toISOString(),
    output,
    meta: meta || null,
  };

  latestSignals[`${symbol}_${tf}`] = msg;
  broadcast(msg);
  return res.json({ status: 'ok' });
});

app.get('/signals', (req, res) => res.json(latestSignals));

const PORT = process.env.PORT || 8080;
server.listen(PORT, () => console.log('Server listening on port', PORT));
