import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'app_data.dart';

class CanvasPainter extends CustomPainter {
  final AppData appData;

  Map directions = {
    "left": Offset(0, 0),
    "up": Offset(128, 0),
    "right": Offset(256, 0),
    "down": Offset(384, 0),
  };

  CanvasPainter(this.appData);

  @override
  void paint(Canvas canvas, Size painterSize) {
    final paint = Paint();

    // Fondo blanco
    paint.color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, painterSize.width, painterSize.height),
      paint,
    );

    // --- 1. Dibujo del mapa ---
    for (var layer in appData.mapLayers) {
      final image = layer.image;
      final tileMap = layer.tileMap;
      final tileWidth = layer.tileWidth;
      final tileHeight = layer.tileHeight;

      for (int row = 0; row < tileMap.length; row++) {
        for (int col = 0; col < tileMap[row].length; col++) {
          int tileIndex = tileMap[row][col];
          if (tileIndex < 0) continue;

          int tilesPerRow = image.width ~/ tileWidth;
          int srcX = (tileIndex % tilesPerRow) * tileWidth;
          int srcY = (tileIndex ~/ tilesPerRow) * tileHeight;

          double dstTileWidth = appData.mapSize.width / tileMap[0].length * 2;
          double dstTileHeight = appData.mapSize.height / tileMap.length * 2;

          Rect srcRect = Rect.fromLTWH(
            srcX.toDouble(),
            srcY.toDouble(),
            tileWidth.toDouble(),
            tileHeight.toDouble(),
          );
          Rect dstRect = Rect.fromLTWH(
            col * dstTileWidth,
            row * dstTileHeight,
            dstTileWidth,
            dstTileHeight,
          );

          canvas.drawImageRect(image, srcRect, dstRect, Paint());
        }
      }
    }

    var gameState = appData.gameState;
    if (gameState.isNotEmpty) {
      // --- 2. Objetos negros (opcional) ---
      if (gameState["objects"] != null) {
        for (var obj in gameState["objects"]) {
          paint.color = Colors.black;
          Offset pos = _serverToPainterCoords(
            Offset(obj["x"], obj["y"]),
            painterSize,
          );
          Size dims = _serverToPainterSize(
            Size(obj["width"], obj["height"]),
            painterSize,
          );
          canvas.drawRect(
            Rect.fromLTWH(pos.dx, pos.dy, dims.width, dims.height),
            paint,
          );
        }
      }

      // --- 3. Proyectiles ---
      if (gameState["projectiles"] != null) {
        for (var projectile in gameState["projectiles"]) {
          Offset pos = _serverToPainterCoords(
            Offset(projectile["x"], projectile["y"]),
            painterSize,
          );

          double radius =
              _serverToPainterRadius(projectile["radius"], painterSize);
          final String imgPath = "sprites/projectile.png";

          if (appData.imagesCache.containsKey(imgPath)) {
            final ui.Image image = appData.imagesCache[imgPath]!;
            final double size = radius * 2;
            canvas.drawImageRect(
              image,
              Rect.fromLTWH(
                  0, 0, image.width.toDouble(), image.height.toDouble()),
              Rect.fromLTWH(pos.dx - radius, pos.dy - radius, size, size),
              Paint(),
            );
          }
        }
      }

      // --- 4. Jugadores ---
      if (gameState["players"] != null) {
        for (var player in gameState["players"]) {
          Offset pos = _serverToPainterCoords(
            Offset(player["x"], player["y"]),
            painterSize,
          );
          double radius = _serverToPainterRadius(player["radius"], painterSize);

          String imgPathArrows = "images/tanks1.png";
          if (appData.imagesCache.containsKey(imgPathArrows)) {
            final ui.Image tilesetImage = appData.imagesCache[imgPathArrows]!;
            Offset tilePos =
                _getArrowTile(player["direction"], player["lastDirection"]);
            Size tileSize = Size(64, 64);
            double painterScale = (2 * radius) / tileSize.width;
            Size painterSize = Size(
              tileSize.width * painterScale,
              tileSize.height * painterScale,
            );
            double x = pos.dx - (painterSize.width / 2);
            double y = pos.dy - (painterSize.height / 2);
            canvas.drawImageRect(
              tilesetImage,
              Rect.fromLTWH(
                  tilePos.dx, tilePos.dy, tileSize.width, tileSize.height),
              Rect.fromLTWH(x, y, painterSize.width, painterSize.height),
              Paint(),
            );
          }
        }
      }

      // --- 5. Texto de ayuda + ID del jugador ---
      String playerId = appData.playerData["id"];
      final paragraphBuilder = ui.ParagraphBuilder(
          ui.ParagraphStyle(textDirection: TextDirection.ltr))
        ..pushStyle(ui.TextStyle(color: Colors.black, fontSize: 14))
        ..addText("Press Up, Down, Left or Right keys to move (id: $playerId)");
      final paragraph = paragraphBuilder.build()
        ..layout(ui.ParagraphConstraints(width: painterSize.width));
      canvas.drawParagraph(
          paragraph, Offset(10, painterSize.height - paragraph.height - 5));

      // --- 6. Indicador de conexión ---
      paint.color = appData.isConnected ? Colors.green : Colors.red;
      canvas.drawCircle(Offset(painterSize.width - 10, 10), 5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  Offset _serverToPainterCoords(Offset serverCoords, Size painterSize) {
    return Offset(
      serverCoords.dx * painterSize.width,
      serverCoords.dy * painterSize.height,
    );
  }

  Size _serverToPainterSize(Size serverSize, Size painterSize) {
    return Size(
      serverSize.width * painterSize.width,
      serverSize.height * painterSize.height,
    );
  }

  double _serverToPainterRadius(double serverRadius, Size painterSize) {
    return serverRadius * painterSize.width;
  }

  Offset _getArrowTile(String direction, String lastDirection) {
    return directions[direction] ?? directions[lastDirection] ?? Offset.zero;
  }
}
