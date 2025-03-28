// app_data.dart
import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'utils_websockets.dart';

class AppData extends ChangeNotifier {
  final WebSocketsHandler _wsHandler = WebSocketsHandler();
  final String _wsServer = "localhost";
  final int _wsPort = 8888;
  bool isConnected = false;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  final Duration _reconnectDelay = Duration(seconds: 3);

  Map<String, ui.Image> imagesCache = {};
  Map<String, dynamic> gameState = {};
  dynamic playerData;
  List<MapLayer> mapLayers = [];
  List<Zone> collisionZones = [];
  Size mapSize = const Size(512, 512);

  AppData() {
    _connectToWebSocket();
  }

  Future<void> loadMapFromJson() async {
    final String jsonString =
        await rootBundle.loadString("assets/game_data.json");
    final Map<String, dynamic> data = jsonDecode(jsonString);
    final level = data["levels"][0];
    final layers = level["layers"] as List<dynamic>;

    mapLayers = [];

    final zones = level["zones"] as List<dynamic>;
    collisionZones = zones
        .where((z) => z["color"] == "blue")
        .map((z) => Zone(
              x: z["x"].toDouble(),
              y: z["y"].toDouble(),
              width: z["width"].toDouble(),
              height: z["height"].toDouble(),
            ))
        .toList();

    for (var layer in layers) {
      if (layer["visible"] != true) continue;

      final String imageFile = layer["tilesSheetFile"];
      final image = await getImage("tiles/$imageFile");

      final tileMap = (layer["tileMap"] as List)
          .map<List<int>>((row) => List<int>.from(row))
          .toList();

      mapLayers.add(
        MapLayer(
          image: image,
          tileMap: tileMap,
          tileWidth: layer["tilesWidth"],
          tileHeight: layer["tilesHeight"],
        ),
      );
    }

    // Preload tank and projectile images
    await getImage("images/tanks1.png");
    await getImage("images/tanks2.png");
    await getImage("images/tanks3.png");
    await getImage("images/tanks4.png");
    await getImage("sprites/projectile.png");

    notifyListeners();
  }

  bool willCollide(double x, double y, String direction) {
    const step = 0.01;
    double newX = x, newY = y;
    switch (direction) {
      case "up":
        newY -= step;
        break;
      case "down":
        newY += step;
        break;
      case "left":
        newX -= step;
        break;
      case "right":
        newX += step;
        break;
      default:
        return false;
    }
    final px = newX * mapSize.width;
    final py = newY * mapSize.height;
    return collisionZones.any((zone) => zone.contains(px, py));
  }

  void _connectToWebSocket() {
    if (_reconnectAttempts >= _maxReconnectAttempts) return;
    isConnected = false;
    notifyListeners();
    _wsHandler.connectToServer(
      _wsServer,
      _wsPort,
      _onWebSocketMessage,
      onError: _onWebSocketError,
      onDone: _onWebSocketClosed,
    );
    isConnected = true;
    _reconnectAttempts = 0;
    notifyListeners();
  }

  void _onWebSocketMessage(String message) {
    try {
      var data = jsonDecode(message);
      if (data["type"] == "update") {
        gameState = {}..addAll(data["gameState"]);
        String? playerId = _wsHandler.socketId;
        if (playerId != null && gameState["players"] is List) {
          playerData = _getPlayerData(playerId);
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  void _onWebSocketError(dynamic error) {
    isConnected = false;
    notifyListeners();
    _scheduleReconnect();
  }

  void _onWebSocketClosed() {
    isConnected = false;
    notifyListeners();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      Future.delayed(_reconnectDelay, () {
        _connectToWebSocket();
      });
    }
  }

  dynamic _getPlayerData(String playerId) {
    return (gameState["players"] as List).firstWhere(
      (player) => player["id"] == playerId,
      orElse: () => {},
    );
  }

  void disconnect() {
    _wsHandler.disconnectFromServer();
    isConnected = false;
    notifyListeners();
  }

  void sendMessage(String message) {
    if (isConnected) _wsHandler.sendMessage(message);
  }

  Future<ui.Image> getImage(String assetName) async {
    if (!imagesCache.containsKey(assetName)) {
      final ByteData data = await rootBundle.load('assets/$assetName');
      final Uint8List bytes = data.buffer.asUint8List();
      imagesCache[assetName] = await decodeImage(bytes);
    }
    return imagesCache[assetName]!;
  }

  Future<ui.Image> decodeImage(Uint8List bytes) {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(bytes, (ui.Image img) => completer.complete(img));
    return completer.future;
  }
}

class MapLayer {
  final ui.Image image;
  final List<List<int>> tileMap;
  final int tileWidth;
  final int tileHeight;

  MapLayer({
    required this.image,
    required this.tileMap,
    required this.tileWidth,
    required this.tileHeight,
  });
}

class Zone {
  final double x, y, width, height;

  Zone({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  bool contains(double px, double py) {
    return px >= x && px <= x + width && py >= y && py <= y + height;
  }
}
