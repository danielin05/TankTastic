import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'app_data.dart';

class CanvasPainter extends CustomPainter {
  final ui.Image layerImage;
  final AppData appData;

  CanvasPainter(this.layerImage, this.appData);

  @override
  void paint(Canvas canvas, Size size) {
    double imageWidth = layerImage.width.toDouble();
    double imageHeight = layerImage.height.toDouble();
    double availableWidth = size.width * 0.95;
    double availableHeight = size.height * 0.95;

    double scaleX = availableWidth / imageWidth;
    double scaleY = availableHeight / imageHeight;
    double scale = scaleX < scaleY ? scaleX : scaleY;

    double scaledWidth = imageWidth * scale;
    double scaledHeight = imageHeight * scale;

    double dx = (size.width - scaledWidth) / 2;
    double dy = (size.height - scaledHeight) / 2;

    // Guardar escala i posició a AppData
    appData.scaleFactor = scale;
    appData.imageOffset = Offset(dx, dy);

    // Dibuixar la imatge escalada
    canvas.drawImageRect(
      layerImage,
      Rect.fromLTWH(0, 0, imageWidth, imageHeight),
      Rect.fromLTWH(dx, dy, scaledWidth, scaledHeight),
      Paint(),
    );

    // Dibuixar cercle vermell si s'està fent drag
    if (appData.selectedSection == "tilemap" &&
        appData.draggingTileIndex != -1 &&
        appData.selectedLevel != -1 &&
        appData.selectedLayer != -1) {
      final level = appData.gameData.levels[appData.selectedLevel];
      final layer = level.layers[appData.selectedLayer];
      final tilesSheetFile = layer.tilesSheetFile;

      if (appData.imagesCache.containsKey(tilesSheetFile)) {
        final ui.Image tilesetImage = appData.imagesCache[tilesSheetFile]!;

        // Dimensions dels tiles
        double tileWidth = layer.tilesWidth.toDouble();
        double tileHeight = layer.tilesHeight.toDouble();
        int tilesetColumns = (tilesetImage.width / tileWidth).floor();

        // Calcular la posició del tile seleccionat dins del tileset
        int tileIndex = appData.draggingTileIndex;
        int tileRow = (tileIndex / tilesetColumns).floor();
        int tileCol = (tileIndex % tilesetColumns);

        double tileX = tileCol * tileWidth;
        double tileY = tileRow * tileHeight;

        double tileHalfW = tileWidth / 2;
        double tileHalfH = tileHeight / 2;

        // Posició on es dibuixarà el tile (seguint el mouse o el dit)
        Offset drawPosition = appData.draggingOffset;

        // Dibuixar el tile seleccionat al canvas
        canvas.drawImageRect(
          tilesetImage,
          Rect.fromLTWH(tileX, tileY, tileWidth, tileHeight),
          Rect.fromLTWH(drawPosition.dx - tileHalfW,
              drawPosition.dy - tileHalfH, tileWidth, tileHeight),
          Paint(),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    return oldDelegate.layerImage != layerImage;
  }
}
