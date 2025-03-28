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
      // --- 2. Proyectiles ---
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

      // --- 3. Jugadores ---
      if (gameState["players"] != null) {
        for (var player in gameState["players"]) {
          Offset pos = _serverToPainterCoords(
            Offset(player["x"], player["y"]),
            painterSize,
          );
          double radius = _serverToPainterRadius(player["radius"], painterSize);

          String imgPath = _getImageFromStringColor(player["color"]);
          if (appData.imagesCache.containsKey(imgPath)) {
            final ui.Image tilesetImage = appData.imagesCache[imgPath]!;
            Offset tilePos =
                _getArrowTile(player["direction"], player["lastDirection"]);
            Size tileSize = Size(64, 64);
            double painterScale = (2 * radius) / tileSize.width;
            Size scaledSize = Size(
              tileSize.width * painterScale,
              tileSize.height * painterScale,
            );
            double x = pos.dx - (scaledSize.width / 2);
            double y = pos.dy - (scaledSize.height / 2);
            canvas.drawImageRect(
              tilesetImage,
              Rect.fromLTWH(
                  tilePos.dx, tilePos.dy, tileSize.width, tileSize.height),
              Rect.fromLTWH(x, y, scaledSize.width, scaledSize.height),
              Paint(),
            );
          }
        }
      }

      // --- 4. Texto de ayuda + ID del jugador ---
      String playerId = appData.playerData["id"];
      Color playerColor = _getColorFromString(appData.playerData["color"]);
      final paragraphBuilder = ui.ParagraphBuilder(
          ui.ParagraphStyle(textDirection: TextDirection.ltr))
        ..pushStyle(ui.TextStyle(color: playerColor, fontSize: 14))
        ..addText("Press Up, Down, Left or Right keys to move (id: $playerId)");
      final paragraph = paragraphBuilder.build()
        ..layout(ui.ParagraphConstraints(width: painterSize.width));
      canvas.drawParagraph(
          paragraph, Offset(10, painterSize.height - paragraph.height - 5));

      // --- 5. Indicador de conexión ---
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
    Map<String, Offset> directions = {
      "left": Offset(0, 0),
      "up": Offset(128, 0),
      "right": Offset(256, 0),
      "down": Offset(384, 0),
    };
    return directions[direction] ?? directions[lastDirection] ?? Offset.zero;
  }

  static String _getImageFromStringColor(String color) {
    switch (color.toLowerCase()) {
      case "green":
        return "images/tanks4.png";
      case "blue":
        return "images/tanks2.png";
      case "brown":
        return "images/tanks1.png";
      case "yellow":
        return "images/tanks3.png";
      default:
        return "images/tanks1.png";
    }
  }

  static Color _getColorFromString(String color) {
    switch (color.toLowerCase()) {
      case "brown":
        return Colors.brown;
      case "green":
        return Colors.green;
      case "blue":
        return Colors.blue;
      case "yellow":
        return Colors.yellow;
      default:
        return Colors.brown;
    }
  }
}
