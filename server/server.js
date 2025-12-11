const express = require('express');
const bodyParser = require('body-parser');
const http = require('http');
const WebSocket = require('ws');

const app = express();
app.use(bodyParser.json());

const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

// keep latest prices in memory (optional, for debugging)
const latestPrices = {};

// helper: send to all connected WS clients
function broadcast(data) {
  const message = JSON.stringify(data);
  wss.clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(message);
    }
  });
}

// MT5 (or any client) will POST ticks here
app.post('/tick', (req, res) => {
  const { symbol, bid, ask, time } = req.body;

  if (!symbol || bid === undefined || ask === undefined) {
    return res.status(400).json({ error: 'Missing fields' });
  }

  const tick = {
    type: 'tick',
    symbol,
    bid,
    ask,
    time: time || new Date().toISOString(),
  };

  latestPrices[symbol] = tick;
  broadcast(tick);

  return res.json({ status: 'ok' });
});

// optional: snapshot endpoint for debugging
app.get('/snapshot', (req, res) => {
  res.json(latestPrices);
});

const PORT = process.env.PORT || 8080;
server.listen(PORT, () => {
  console.log('Tick server listening on port', PORT);
});
