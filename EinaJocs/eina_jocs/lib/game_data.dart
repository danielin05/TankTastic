import 'game_level.dart';

class GameData {
  final String name;
  final List<GameLevel> levels;

  GameData({
    required this.name,
    required this.levels,
  });

  // Constructor de fàbrica per crear una instància des d'un Map (JSON)
  factory GameData.fromJson(Map<String, dynamic> json) {
    return GameData(
      name: json['name'] as String,
      levels: (json['levels'] as List<dynamic>)
          .map((level) => GameLevel.fromJson(level))
          .toList(),
    );
  }

  // Convertir l'objecte a JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'levels': levels.map((level) => level.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'Game(name: $name, levels: $levels)';
  }
}
