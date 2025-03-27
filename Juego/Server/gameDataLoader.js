// gameDataLoader.js
'use strict';

const fs = require('fs');
const path = require('path');

class GameDataLoader {
    constructor() {
        this.data = null;
        this.filePath = path.join(__dirname, 'public', 'game_data.json');

        try {
            const rawData = fs.readFileSync(this.filePath, 'utf-8');
            this.data = JSON.parse(rawData);
        } catch (error) {
            console.error('Error al leer el archivo game_data.json:', error);
            this.data = { levels: [] };
        }
    }

    /**
     * Devuelve todos los niveles cargados desde el archivo JSON
     * @returns {Array} Array de niveles
     */
    getLevels() {
        return this.data.levels || [];
    }

    /**
     * Devuelve un nivel específico por su nombre
     * @param {string} name - Nombre del nivel a buscar
     * @returns {Object|null} Nivel si se encuentra, null si no
     */
    getLevel(name) {
        const levels = this.getLevels();
        return levels.find(level => level.name === name) || null;
    }

    /**
     * Devuelve las zonas de un nivel específico
     * @param {string} levelName - Nombre del nivel
     * @returns {Array} Zonas definidas en el nivel (vacío si no hay)
     */
    getZones(levelName) {
        const level = this.getLevel(levelName);
        return level && Array.isArray(level.zones) ? level.zones : [];
    }

    /**
     * Devuelve las capas (layers) de un nivel
     * @param {string} levelName - Nombre del nivel
     * @returns {Array} Capas (layers) del nivel
     */
    getLayers(levelName) {
        const level = this.getLevel(levelName);
        return level && Array.isArray(level.layers) ? level.layers : [];
    }

    /**
     * Devuelve los sprites definidos en un nivel
     * @param {string} levelName - Nombre del nivel
     * @returns {Array} Sprites del nivel
     */
    getSprites(levelName) {
        const level = this.getLevel(levelName);
        return level && Array.isArray(level.sprites) ? level.sprites : [];
    }
}

module.exports = GameDataLoader;
