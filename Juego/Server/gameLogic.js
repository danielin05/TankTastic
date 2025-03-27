'use strict';

const GameDataLoader = require('./gameDataLoader');
const fs = require('fs');

const COLORS = ['brown', 'blue', 'yellow', 'green'];
const OBJECT_WIDTH = 0.075;
const OBJECT_HEIGHT = 0.025;
const SPEED = 0.2;
const INITIAL_RADIUS = 0.05;

// Direcciones posibles para el movimiento de los jugadores
const DIRECTIONS = {
    "up":         { dx: 0, dy: -1 },
    "upLeft":     { dx: -1, dy: -1 },
    "left":       { dx: -1, dy: 0 },
    "downLeft":   { dx: -1, dy: 1 },
    "down":       { dx: 0, dy: 1 },
    "downRight":  { dx: 1, dy: 1 },
    "right":      { dx: 1, dy: 0 },
    "upRight":    { dx: 1, dy: -1 },
    "none":       { dx: 0, dy: 0 }
};

class GameLogic {
    constructor() {
        // Cargar los datos del nivel desde el archivo JSON
        const loader = new GameDataLoader();
        this.levelData = loader.getLevel("Castle") || {};

        // Almacenar capas, zonas y sprites desde el JSON
        this.layers = this.levelData.layers || [];
        this.zones = this.levelData.zones || [];
        this.sprites = this.levelData.sprites || [];

        // Inicialización de objetos móviles (obstáculos) y jugadores
        this.objects = [];
        this.players = new Map();
        this.zones = [];
        this.projectiles = []; 

        // Leer zonas del archivo game_data.json
        const gameData = JSON.parse(fs.readFileSync('./public/game_data.json', 'utf8'));
        const zones = gameData.levels[0].zones;

        // Filtrar zonas de colisión (color azul)
        this.zones = zones.filter(zone => zone.color === 'blue');
        
        // Rectángulos en movimiento (ejemplo del juego original)
        for (let i = 0; i < 10; i++) {
            this.objects.push({
                x: Math.random() * (1 - OBJECT_WIDTH),
                y: Math.random() * (1 - OBJECT_HEIGHT),
                width: OBJECT_WIDTH,
                height: OBJECT_HEIGHT,
                speed: SPEED,
                direction: Math.random() > 0.5 ? 1 : -1
            });
        }

        // Crear algunos objetos rectangulares que se mueven automáticamente
        for (let i = 0; i < 10; i++) {
            this.objects.push({
                x: Math.random() * (1 - OBJECT_WIDTH),
                y: Math.random() * (1 - OBJECT_HEIGHT),
                width: OBJECT_WIDTH,
                height: OBJECT_HEIGHT,
                speed: SPEED,
                direction: Math.random() > 0.5 ? 1 : -1
            });
        }
    }

    // Añadir un nuevo jugador
    addClient(id) {
        let pos = this.getValidPosition();
        let color = this.getAvailableColor();

        this.players.set(id, {
            id,
            x: pos.x,
            y: pos.y,
            speed: SPEED,
            direction: "none",
            lastDirection: "down",
            color,
            radius: INITIAL_RADIUS,
            alive:true
        });

        return this.players.get(id);
    }

    // Eliminar un jugador
    removeClient(id) {
        this.players.delete(id);
    }

    // Manejar los mensajes recibidos desde un cliente
    handleMessage(id, msg) {
        try {
            let obj = JSON.parse(msg);
            if (!obj.type) return;

            switch (obj.type) {
                case "direction":
                    if (this.players.has(id) && DIRECTIONS[obj.value]) {
                      this.players.get(id).direction = obj.value;
                      if(obj.value != "none"){
                          this.players.get(id).lastDirection = obj.value;
                      }
                    }
                case "shoot":
                    if (this.players.has(id)) {
                        let player = this.players.get(id);
                        if (obj.value) {
                            const dir = DIRECTIONS[player.lastDirection];
                            if (dir.dx !== 0 || dir.dy !== 0) {
                                this.projectiles.push({
                                    x: player.x,
                                    y: player.y,
                                    dx: dir.dx,
                                    dy: dir.dy,
                                    speed: 0.5,
                                    radius: 0.01,
                                    ownerId: id
                                });
                            }
                        }
                    }
                    break;

                default:
                    break;
            }
        } catch (error) {
            console.error("Error al procesar mensaje del cliente:", error);
        }
    }

    // Actualizar el estado del juego en cada frame del loop
    updateGame(fps) {
        let deltaTime = 1 / fps;
    
        // Mover obstáculos rectangulares (objetos móviles)
        this.objects.forEach(obj => {
            obj.x += obj.speed * obj.direction * deltaTime;
            if (obj.x <= 0 || obj.x + obj.width >= 1) {
                obj.direction *= -1;
            }
        });
    
        // Actualizar jugadores
        this.players.forEach(client => {
            if (!client.alive) return; // Si está destruido, no se actualiza
    
            let moveVector = DIRECTIONS[client.direction];
    
            // Guardar posición anterior antes del movimiento
            let prevX = client.x;
            let prevY = client.y;
    
            // Aplicar movimiento
            client.x = Math.max(0, Math.min(1, client.x + client.speed * moveVector.dx * deltaTime));
            client.y = Math.max(0, Math.min(1, client.y + client.speed * moveVector.dy * deltaTime));
    
            // Comprobar colisión con zonas (paredes del mapa)
            for (let zone of this.zones) {
                const mapSize = 512; // tamaño real del canvas
                let zx = zone.x / mapSize;
                let zy = zone.y / mapSize;
                let zw = zone.width / mapSize;
                let zh = zone.height / mapSize;
    
                if (this.isCircleRectColliding(client.x, client.y, client.radius, zx, zy, zw, zh)) {
                    client.x = prevX;
                    client.y = prevY;
                    break;
                }
            }
    
            // Colisiones con objetos móviles (y eliminar el objeto si colisiona)
            this.objects = this.objects.filter(obj => {
                if (this.isCircleRectColliding(client.x, client.y, client.radius, obj.x, obj.y, obj.width, obj.height)) {
                    client.radius *= 1.1;
                    client.speed *= 1.05;
                    return false;
                }
                return true;
            });
    
            // Detectar si el jugador está disparando (se crea proyectil en handleMessage)
            if (client.shoot) {
                console.log(`Jugador ${client.id} está disparando`);
            }
        });
    
        // Actualizar proyectiles
        this.projectiles = this.projectiles.filter(projectile => {
            // Mover el proyectil
            projectile.x += projectile.dx * projectile.speed * deltaTime;
            projectile.y += projectile.dy * projectile.speed * deltaTime;
    
            // Comprobar colisión con zonas del mapa (paredes)
            for (let zone of this.zones) {
                const mapSize = 512;
                let zx = zone.x / mapSize;
                let zy = zone.y / mapSize;
                let zw = zone.width / mapSize;
                let zh = zone.height / mapSize;
    
                if (this.isCircleRectColliding(projectile.x, projectile.y, projectile.radius, zx, zy, zw, zh)) {
                    return false; // explota contra la pared
                }
            }
    
            // Comprobar colisión con jugadores
            for (let [id, player] of this.players.entries()) {
                if (
                    id !== projectile.ownerId &&
                    player.alive &&
                    this.isCircleCircleColliding(projectile.x, projectile.y, projectile.radius, player.x, player.y, player.radius)
                ) {
                    console.log(`Jugador ${projectile.ownerId} ha eliminado a ${id}`);

                    // Cambiar sprite y desactivar colisión
                    player.destroyed = true;
                    player.spriteIndex = 9; // Sprite de destrucción
                    player.radius = 0;
                    player.speed = 0;
                    
                    // Avisar al jugador eliminado
                    this.sendTo(id, {
                        type: "eliminated",
                        message: "Has sido destruido"
                    });
                    
                    // Avisar al resto
                    this.broadcastExcept(id, {
                        type: "player_destroyed",
                        id: id
                    });
                    
                    return false;
                }
            }
    
            return true; // sigue activo si no ha colisionado
        });
    }
    

    // Obtener una posición válida para un nuevo jugador
    getValidPosition() {
        let x, y;
        let isValid = false;
        while (!isValid) {
            x = Math.random() * (1 - OBJECT_WIDTH);
            y = Math.random() * (1 - OBJECT_HEIGHT);
            isValid = true;

            // Evitar colisiones con obstáculos
            this.objects.forEach(obj => {
                if (this.isCircleRectColliding(x, y, INITIAL_RADIUS, obj.x, obj.y, obj.width, obj.height)) {
                    isValid = false;
                }
            });

            // Evitar colisiones con otros jugadores
            this.players.forEach(client => {
                if (this.isCircleCircleColliding(x, y, INITIAL_RADIUS, client.x, client.y, client.radius)) {
                    isValid = false;
                }
            });
        }
        return { x, y };
    }

    // Obtener un color disponible para un nuevo jugador
    getAvailableColor() {
        let assignedColors = new Set(Array.from(this.players.values()).map(client => client.color));
        let availableColors = COLORS.filter(color => !assignedColors.has(color));
        return availableColors.length > 0 
            ? availableColors[Math.floor(Math.random() * availableColors.length)]
            : COLORS[Math.floor(Math.random() * COLORS.length)];
    }

    // Comprobar colisión entre un círculo y un rectángulo
    isCircleRectColliding(cx, cy, r, rx, ry, rw, rh) {
        let closestX = Math.max(rx, Math.min(cx, rx + rw));
        let closestY = Math.max(ry, Math.min(cy, ry + rh));
        let dx = cx - closestX;
        let dy = cy - closestY;
        return (dx * dx + dy * dy) <= (r * r);
    }

    // Comprobar colisión entre dos círculos
    isCircleCircleColliding(x1, y1, r1, x2, y2, r2) {
        let dx = x1 - x2;
        let dy = y1 - y2;
        return (dx * dx + dy * dy) <= ((r1 + r2) * (r1 + r2));
    }

    // Obtener el estado actual del juego (incluye datos del mapa)
    getGameState() {
        return {
            objects: this.objects,
            players: Array.from(this.players.values()),
            layers: this.layers,
            zones: this.zones,
            sprites: this.sprites,
            projectiles: this.projectiles
        };
    }
    // Envía un mensaje a un cliente específico
    sendTo(id, obj) {
        let socket = this.ws?.getSocketById?.(id);
        if (socket && socket.readyState === 1) {
            socket.send(JSON.stringify(obj));
        }
    }

    // Envía a todos menos al indicado
    broadcastExcept(exceptId, obj) {
        if (!this.ws) return;
        for (let [socket, meta] of this.ws.socketsClients.entries()) {
            if (meta.id !== exceptId && socket.readyState === 1) {
                socket.send(JSON.stringify(obj));
            }
        }
    }

}

module.exports = GameLogic;
