'use strict';

const COLORS = ['brown', 'blue', 'yellow', 'green'];
const OBJECT_WIDTH = 0.075;
const OBJECT_HEIGHT = 0.025;
const SPEED = 0.2;
const INITIAL_RADIUS = 0.035;

const DIRECTIONS = {
    "up":         { dx: 0, dy: -1 },
    // "upLeft":     { dx: -1, dy: -1 },
    "left":       { dx: -1, dy: 0 },
    // "downLeft":   { dx: -1, dy: 1 },
    "down":       { dx: 0, dy: 1 },
    // "downRight":  { dx: 1, dy: 1 },
    "right":      { dx: 1, dy: 0 },
    // "upRight":    { dx: 1, dy: -1 },
    "none":       { dx: 0, dy: 0 }
};

class GameLogic {
    constructor() {
        this.objects = [];
        this.players = new Map();
        this.zones = [];
        this.projectiles = []; 

        // Rectangles que mou el servidor
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

    // Es connecta un client/jugador
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
            radius: INITIAL_RADIUS
        });

        return this.players.get(id);
    }

    // Es desconnecta un client/jugador
    removeClient(id) {
        this.players.delete(id);
    }

    // Tractar un missatge d'un client/jugador
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
              break;
              case "shoot":
                if (this.players.has(id)) {
                    let player = this.players.get(id);
                    let now = Date.now();

                    if (!player.lastShotTime || (now - player.lastShotTime >= 1000)) {  // 2 segundos (2000 ms)
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

                            player.shoot = true;
                            player.lastShotTime = now;  // Guardar el tiempo del disparo
                        }
                    }
                }
                break;
            default:
              break;
          }
        } catch (error) {}
    }

    // Blucle de joc (funció que s'executa contínuament)
    updateGame(fps) {
        let deltaTime = 1 / fps;
        let proyectileDeltaTime = 3 / fps;
    
        // Mover los proyectiles
        this.projectiles = this.projectiles.filter(projectile => {
            projectile.x += projectile.dx * projectile.speed * proyectileDeltaTime;
            projectile.y += projectile.dy * projectile.speed * proyectileDeltaTime;
    
            // Comprobar colisión con los jugadores
            for (let player of this.players.values()) {
                if (player.id !== projectile.ownerId && this.isCircleCircleColliding(
                    projectile.x, projectile.y, projectile.radius,
                    player.x, player.y, player.radius
                )) {
                    console.log(`Jugador ${player.id} ha sido alcanzado por un disparo!`);
                    return false; // Eliminar el proyectil
                }
            }
    
            // Eliminar el proyectil si sale de los límites del mapa
            return projectile.x >= 0 && projectile.x <= 1 && projectile.y >= 0 && projectile.y <= 1;
        });
    
        // Mover jugadores y detectar colisiones con objetos
        this.players.forEach(client => {
            let moveVector = DIRECTIONS[client.direction];
            client.x = Math.max(0, Math.min(1, client.x + client.speed * moveVector.dx * deltaTime));
            client.y = Math.max(0, Math.min(1, client.y + client.speed * moveVector.dy * deltaTime));
        });
    }
    

    // Obtenir una posició on no hi h ha ni objectes ni jugadors
    getValidPosition() {
        let x, y;
        let isValid = false;
        while (!isValid) {
            x = Math.random() * (1 - OBJECT_WIDTH);
            y = Math.random() * (1 - OBJECT_HEIGHT);
            isValid = true;

            this.objects.forEach(obj => {
                if (this.isCircleRectColliding(x, y, INITIAL_RADIUS, obj.x, obj.y, obj.width, obj.height)) {
                    isValid = false;
                }
            });

            this.players.forEach(client => {
                if (this.isCircleCircleColliding(x, y, INITIAL_RADIUS, client.x, client.y, client.radius)) {
                    isValid = false;
                }
            });
        }
        return { x, y };
    }

    // Obtenir un color aleatori que no ha estat escollit abans
    getAvailableColor() {
        let assignedColors = new Set(Array.from(this.players.values()).map(client => client.color));
        let availableColors = COLORS.filter(color => !assignedColors.has(color));
        return availableColors.length > 0 
          ? availableColors[Math.floor(Math.random() * availableColors.length)]
          : COLORS[Math.floor(Math.random() * COLORS.length)];
    }

    // Detectar si un cercle i un rectangle es sobreposen
    isCircleRectColliding(cx, cy, r, rx, ry, rw, rh) {
        let closestX = Math.max(rx, Math.min(cx, rx + rw));
        let closestY = Math.max(ry, Math.min(cy, ry + rh));
        let dx = cx - closestX;
        let dy = cy - closestY;
        return (dx * dx + dy * dy) <= (r * r);
    }

    // Detectar si dos cercles es sobreposen
    isCircleCircleColliding(x1, y1, r1, x2, y2, r2) {
        let dx = x1 - x2;
        let dy = y1 - y2;
        return (dx * dx + dy * dy) <= ((r1 + r2) * (r1 + r2));
    }

    // Retorna l'estat del joc (per enviar-lo als clients/jugadors)
    getGameState() {
        return {
            objects: this.objects,
            players: Array.from(this.players.values()),
            projectiles: this.projectiles // Enviar proyectiles a los clientes
        };
    }
}

module.exports = GameLogic;