const express = require('express');
const http = require('http');
const GameLogic = require('./gameLogic');
const WebSockets = require('./utilsWebSockets');
const GameLoop = require('./utilsGameLoop');

const port = process.env.PORT || 8888;
const debug = true;

// Inicializar componentes
const app = express();
const httpServer = http.createServer(app);
const ws = new WebSockets();
const game = new GameLogic();
const gameLoop = new GameLoop();

// Servir archivos estáticos desde /public
app.use(express.static('public'));
app.use(express.json());

// Iniciar servidor HTTP
httpServer.listen(port, () => {
    console.log(`Servidor HTTP escuchando en http://localhost:${port}`);
});

// Inicializar WebSockets
ws.init(httpServer, port);
game.ws = ws; // Para que gameLogic tenga acceso a los sockets

// Conexión de cliente
ws.onConnection = (socket, id) => {
    if (debug) console.log("Cliente conectado:", id);
    game.addClient(id);
};

// Mensajes entrantes
ws.onMessage = (socket, id, msg) => {
    if (debug) console.log(`Mensaje de ${id}: ${msg.substring(0, 32)}...`);
    game.handleMessage(id, msg);
};

// Desconexión de cliente
ws.onClose = (socket, id) => {
    if (debug) console.log("Cliente desconectado:", id);
    game.removeClient(id);
    ws.broadcast(JSON.stringify({ type: "disconnected", from: id }));
};

// Bucle de juego
gameLoop.run = (fps) => {
    game.updateGame(fps);
    ws.broadcast(JSON.stringify({
        type: "update",
        gameState: game.getGameState()
    }));
};

// Iniciar el loop
gameLoop.start();

// Cierre del servidor
process.on('SIGTERM', shutDown);
process.on('SIGINT', shutDown);

function shutDown() {
    console.log('Servidor cerrando...');
    httpServer.close();
    ws.end();
    gameLoop.stop();
    process.exit(0);
}
