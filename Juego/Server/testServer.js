// testClient.js
const WebSocket = require('ws');

const ws = new WebSocket('ws://localhost:8888');

ws.on('open', () => {
  console.log('Conectado al servidor WebSocket');
  ws.send(JSON.stringify({ type: 'direction', value: 'right' }));
  setTimeout(() => {
    ws.send(JSON.stringify({ type: 'shoot', value: true }));
  }, 1000);
});

ws.on('message', (msg) => {
  const data = JSON.parse(msg);
  console.log('Mensaje del servidor:', data);
});