const WebSocket = require('ws');
const { v4: uuidv4 } = require('uuid');

class WebSockets {
    init(httpServer, port) {
        this.onConnection = () => {};
        this.onMessage = () => {};
        this.onClose = () => {};

        this.ws = new WebSocket.Server({ server: httpServer });
        this.socketsClients = new Map();

        console.log(`WebSockets escuchando en el puerto ${port}`);

        this.ws.on('connection', ws => this.newConnection(ws));
    }

    end() {
        this.ws.close();
    }

    newConnection(con) {
        const id = "C" + uuidv4().substring(0, 5).toUpperCase();
        this.socketsClients.set(con, { id });

        con.send(JSON.stringify({ type: "welcome", id }));
        this.broadcast(JSON.stringify({ type: "newClient", id }));

        if (this.onConnection) this.onConnection(con, id);

        con.on("close", () => {
            this.closeConnection(con);
            this.socketsClients.delete(con);
        });

        con.on("message", msg => this.onMessage(con, id, msg.toString()));
    }

    closeConnection(con) {
        const meta = this.socketsClients.get(con);
        if (this.onClose && meta) this.onClose(con, meta.id);
    }

    broadcast(msg) {
        this.ws.clients.forEach(client => {
            if (client.readyState === WebSocket.OPEN) {
                client.send(msg);
            }
        });
    }

    getSocketById(id) {
        for (let [socket, meta] of this.socketsClients.entries()) {
            if (meta.id === id) return socket;
        }
        return null;
    }

    getClientsData() {
        return Array.from(this.socketsClients.values());
    }
}

module.exports = WebSockets;
