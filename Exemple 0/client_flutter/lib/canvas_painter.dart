import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'app_data.dart';

class CanvasPainter extends CustomPainter {
  final AppData appData;

  Map directions = {
    "left": Offset(0, 0),
    // "upLeft": Offset(64, 0),
    "up": Offset(128, 0),
    // "upRight": Offset(192, 0),
    "right": Offset(256, 0),
    // "downRight": Offset(320, 0),
    "down": Offset(384, 0),
    // "downLeft": Offset(448, 0),
  };

  CanvasPainter(this.appData);

  @override
  void paint(Canvas canvas, Size painterSize) {
    final paint = Paint();
    paint.color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, painterSize.width, painterSize.height),
      paint,
    );

    // Dibuixar l'estat del joc
    var gameState = appData.gameState;
    if (gameState.isNotEmpty) {
      // Dibuixar els objectes (quadres negres)
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

      // Dibuixar els jugadors (cercles de colors)
      if (gameState["players"] != null) {
        for (var player in gameState["players"]) {
          paint.color = Colors.transparent;
          Offset pos = _serverToPainterCoords(
            Offset(player["x"], player["y"]),
            painterSize,
          );

          double radius = _serverToPainterRadius(player["radius"], painterSize);
          canvas.drawCircle(pos, radius, paint);

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
                tilePos.dx,
                tilePos.dy,
                tileSize.width,
                tileSize.height,
              ),
              Rect.fromLTWH(x, y, painterSize.width, painterSize.height),
              Paint(),
            );
          }
        }
      }

      // Escriure el text informatiu i l'identificador d'usuari
      String playerId = appData.playerData["id"];
      Color playerColor = Colors.black;
      final paragraphStyle = ui.ParagraphStyle(
        textDirection: TextDirection.ltr,
      );
      final textStyle = ui.TextStyle(color: playerColor, fontSize: 14);
      final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
        ..pushStyle(textStyle)
        ..addText(
          "Press Up, Down, Left or Right keys to move (id: $playerId)",
        );
      final paragraph = paragraphBuilder.build();
      paragraph.layout(ui.ParagraphConstraints(width: painterSize.width));
      canvas.drawParagraph(
        paragraph,
        Offset(10, painterSize.height - paragraph.height - 5),
      );

      // Mostrar el cercle de connexió (amunt a la dreta)
      paint.color = appData.isConnected ? Colors.green : Colors.red;
      canvas.drawCircle(Offset(painterSize.width - 10, 10), 5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  // Passar coordenades del servidor a coordenades de l'aplicació
  Offset _serverToPainterCoords(Offset serverCoords, Size painterSize) {
    return Offset(
      serverCoords.dx * painterSize.width,
      serverCoords.dy * painterSize.height,
    );
  }

  // Passar mida del servidor a coordenades de l'aplicació
  Size _serverToPainterSize(Size serverSize, Size painterSize) {
    return Size(
      serverSize.width * painterSize.width,
      serverSize.height * painterSize.height,
    );
  }

  // Passar radi del servidor a radi de l'aplicació
  double _serverToPainterRadius(double serverRadius, Size painterSize) {
    return serverRadius * painterSize.width;
  }

  // Agafar la part del dibuix que té la fletxa de direcció a dibuixar
  Offset _getArrowTile(String direction, String lastDirection) {
    switch (direction) {
      case "left":
        return directions[direction];
      // case "upLeft":
      //   return directions[direction];
      case "up":
        return directions[direction];
      // case "upRight":
      //   return directions[direction];
      case "right":
        return directions[direction];
      // case "downRight":
      //   return directions[direction];
      case "down":
        return directions[direction];
      // case "downLeft":
      //   return directions[direction];
      default:
        return directions[lastDirection];
    }
  }
}
