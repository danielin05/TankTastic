import 'game_layer.dart';
import 'game_zone.dart';
import 'game_sprite.dart';

class GameLevel {
  final String name;
  final String description;
  final List<GameLayer> layers;
  final List<GameZone> zones;
  final List<GameSprite> sprites;

  GameLevel({
    required this.name,
    required this.description,
    required this.layers,
    required this.zones,
    required this.sprites,
  });

  // Constructor de fàbrica per crear una instància des d'un Map (JSON)
  factory GameLevel.fromJson(Map<String, dynamic> json) {
    return GameLevel(
      name: json['name'] as String,
      description: json['description'] as String,
      layers: (json['layers'] as List<dynamic>)
          .map((layer) => GameLayer.fromJson(layer))
          .toList(),
      zones: (json['zones'] as List<dynamic>)
          .map((zone) => GameZone.fromJson(zone))
          .toList(),
      sprites: (json['sprites'] as List<dynamic>)
          .map((item) => GameSprite.fromJson(item))
          .toList(),
    );
  }

  // Convertir l'objecte a JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'layers': layers.map((layer) => layer.toJson()).toList(),
      'zones': zones.map((zone) => zone.toJson()).toList(),
      'sprites': sprites.map((item) => item.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'GameLevel(name: $name, description: $description, layers: $layers, zones: $zones, sprites: $sprites)';
  }
}
