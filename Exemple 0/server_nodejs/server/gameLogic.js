'use strict';

const COLORS = ['brown', 'blue', 'yellow', 'green'];
const SPEED = 0.2;
const INITIAL_RADIUS = 0.05;

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
        this.players = new Map();
        this.projectiles = [];
    }

    addClient(id) {
        const color = this.getAvailableColor();
        const position = this.getSpawnPosition(color);

        this.players.set(id, {
            id,
            x: position.x,
            y: position.y,
            speed: SPEED,
            direction: "none",
            lastDirection: "down",
            color,
            radius: INITIAL_RADIUS,
        });

        return this.players.get(id);
    }

    removeClient(id) {
        this.players.delete(id);
    }

    handleMessage(id, msg) {
        try {
            const obj = JSON.parse(msg);
            if (!obj.type) return;

            const player = this.players.get(id);
            if (!player) return;

            switch (obj.type) {
                case "direction":
                    if (DIRECTIONS[obj.value]) {
                        if (obj.value !== "none") {
                            player.lastDirection = obj.value;
                        }
                        player.direction = obj.value;
                    }
                    break;

                case "shoot":
                    this.spawnProjectile(player);
                    break;
            }
        } catch (err) {
            console.error("Invalid message from client", err);
        }
    }

    updateGame(fps) {
        const deltaTime = 1 / fps;

        this.players.forEach(player => {
            const vector = DIRECTIONS[player.direction];
            player.x = Math.max(0, Math.min(1, player.x + vector.dx * player.speed * deltaTime));
            player.y = Math.max(0, Math.min(1, player.y + vector.dy * player.speed * deltaTime));
        });

        this.projectiles.forEach(projectile => {
            const vector = DIRECTIONS[projectile.direction];
            projectile.x += vector.dx * projectile.speed * deltaTime;
            projectile.y += vector.dy * projectile.speed * deltaTime;
        });

        this.projectiles = this.projectiles.filter(p => p.x >= 0 && p.x <= 1 && p.y >= 0 && p.y <= 1);
    }

    spawnProjectile(player) {
        this.projectiles.push({
            x: player.x,
            y: player.y,
            direction: player.lastDirection,
            speed: 0.5,
            radius: 0.015,
            color: player.color,
        });
    }

    getAvailableColor() {
        const assigned = new Set([...this.players.values()].map(p => p.color));
        const available = COLORS.filter(c => !assigned.has(c));
        return available.length > 0 ? available[0] : COLORS[Math.floor(Math.random() * COLORS.length)];
    }

    getSpawnPosition(color) {
        switch (color) {
            case "brown": return { x: 64 / 512, y: 240 / 512 };
            case "blue": return { x: 240 / 512, y: 64 / 512 };
            case "yellow": return { x: 416 / 512, y: 240 / 512 };
            case "green": return { x: 240 / 512, y: 400 / 512 };
            default: return { x: Math.random(), y: Math.random() };
        }
    }

    getGameState() {
        return {
            players: [...this.players.values()],
            projectiles: this.projectiles,
        };
    }
}

module.exports = GameLogic;
