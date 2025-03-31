'use strict';

const COLORS = ['brown', 'blue', 'yellow', 'green'];
const SPEED = 0.15;
const INITIAL_RADIUS = 0.03;

const DIRECTIONS = {
    "up":         { dx: 0, dy: -1 },
    "left":       { dx: -1, dy: 0 },
    "down":       { dx: 0, dy: 1 },
    "right":      { dx: 1, dy: 0 },
    "none":       { dx: 0, dy: 0 }
};

const fs = require('fs');
const GameDataLoader = require('./gameDataLoader');

class GameLogic {
    constructor() {
        const loader = new GameDataLoader();
        this.levelData = loader.getLevel("Castle") || {};
        this.layers = this.levelData.layers || [];
        this.sprites = this.levelData.sprites || [];
        this.zones = [];
        this.players = new Map();
        this.projectiles = [];

        const wallLayer = this.layers.find(layer => layer.name === "CastleBorder");
        if (wallLayer) {
            const tileMap = wallLayer.tileMap;
            const tileWidth = wallLayer.tilesWidth / 512;
            const tileHeight = wallLayer.tilesHeight / 512;

            tileMap.forEach((row, rowIndex) => {
                row.forEach((tile, colIndex) => {
                    if (tile !== -1) {
                        this.zones.push({
                            x: colIndex * tileWidth,
                            y: rowIndex * tileHeight,
                            width: tileWidth,
                            height: tileHeight
                        });
                    }
                });
            });
        }
    }

    addClient(id) {
        let color = this.getAvailableColor();
        let pos = this.getSpawnPosition(color);

        this.players.set(id, {
            id,
            x: pos.x,
            y: pos.y,
            speed: SPEED,
            direction: "none",
            lastDirection: "down",
            color,
            radius: INITIAL_RADIUS,
            alive: true
        });

        return this.players.get(id);
    }

    getSpawnPosition(color) {
        switch (color) {
            case "brown": return { x: 64 / 512, y: 250 / 512 };
            case "blue": return { x: 240 / 512, y: 64 / 512 };
            case "yellow": return { x: 416 / 512, y: 240 / 512 };
            case "green": return { x: 240 / 512, y: 400 / 512 };
            default: return this.getValidPosition();
        }
    }

    removeClient(id) {
        this.players.delete(id);
    }

    handleMessage(id, msg) {
        try {
            let obj = JSON.parse(msg);
            if (!obj.type) return;

            switch (obj.type) {
                case "direction":
                    if (this.players.has(id) && DIRECTIONS[obj.value]) {
                        this.players.get(id).direction = obj.value;
                        if (obj.value !== "none") {
                            this.players.get(id).lastDirection = obj.value;
                        }
                    }
                    break;

                case "shoot":
                    if (this.players.has(id)) {
                        let player = this.players.get(id);
                        let now = Date.now();

                        if (!player.lastShotTime || (now - player.lastShotTime >= 2000)) {
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

                                player.lastShotTime = now;
                            }
                        }
                    }
                    break;
            }
        } catch (error) {
            console.error("Error al procesar mensaje del cliente:", error);
        }
    }

    updateGame(fps) {
        let deltaTime = 1 / fps;
        let projectileDeltaTime = 3 / fps;

        this.projectiles = this.projectiles.filter(projectile => {
            projectile.x += projectile.dx * projectile.speed * projectileDeltaTime;
            projectile.y += projectile.dy * projectile.speed * projectileDeltaTime;

            for (let player of this.players.values()) {
                if (player.id !== projectile.ownerId && this.isCircleCircleColliding(
                    projectile.x, projectile.y, projectile.radius,
                    player.x, player.y, player.radius
                )) {
                    console.log(`Jugador ${player.id} ha sido alcanzado por un disparo!`);
                    return false;
                }
            }

            return projectile.x >= 0 && projectile.x <= 1 && projectile.y >= 0 && projectile.y <= 1;
        });

        this.players.forEach(client => {
            if (!client.alive) return;

            let moveVector = DIRECTIONS[client.direction];
            let nextX = client.x + client.speed * moveVector.dx * deltaTime;
            let nextY = client.y + client.speed * moveVector.dy * deltaTime;

            if (!this.checkCollision(nextX, nextY, client.radius)) {
                client.x = Math.max(0, Math.min(1, nextX));
                client.y = Math.max(0, Math.min(1, nextY));
            }
        });
    }

    checkCollision(x, y, radius) {
        return this.zones.some(zone => {
            const closestX = Math.max(zone.x, Math.min(x, zone.x + zone.width));
            const closestY = Math.max(zone.y, Math.min(y, zone.y + zone.height));
            const dx = x - closestX;
            const dy = y - closestY;
            return dx * dx + dy * dy < radius * radius;
        });
    }

    getValidPosition() {
        let x, y;
        let isValid = false;
        while (!isValid) {
            x = Math.random();
            y = Math.random();
            isValid = true;

            this.players.forEach(client => {
                if (this.isCircleCircleColliding(x, y, INITIAL_RADIUS, client.x, client.y, client.radius)) {
                    isValid = false;
                }
            });

            if (this.checkCollision(x, y, INITIAL_RADIUS)) {
                isValid = false;
            }
        }
        return { x, y };
    }

    getAvailableColor() {
        const assigned = new Set([...this.players.values()].map(p => p.color));
        const available = COLORS.filter(c => !assigned.has(c));
        return available.length > 0 ? available[0] : COLORS[Math.floor(Math.random() * COLORS.length)];
    }

    isCircleCircleColliding(x1, y1, r1, x2, y2, r2) {
        let dx = x1 - x2;
        let dy = y1 - y2;
        return (dx * dx + dy * dy) <= ((r1 + r2) * (r1 + r2));
    }

    getGameState() {
        return {
            players: Array.from(this.players.values()),
            projectiles: this.projectiles
        };
    }
}

module.exports = GameLogic;