const { WebSocketServer } = require('ws');

const PORT = 8080;
const wss = new WebSocketServer({ port: PORT });

wss.on('connection', (ws) => {
  ws.on('message', (data) => {
    // Echo back the exact same message
    ws.send(data.toString());
  });

  ws.on('error', () => {
    // Silently handle errors
  });
});

console.log(`WebSocket echo server listening on port ${PORT}`);
