import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_data.dart';

class LayoutTilemaps extends StatefulWidget {
  const LayoutTilemaps({super.key});
  @override
  LayoutTilemapsState createState() => LayoutTilemapsState();
}

class LayoutTilemapsState extends State<LayoutTilemaps> {
  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    if (appData.selectedLevel == -1 || appData.selectedLayer == -1) {
      return const Center(child: Text('Select a layer to edit its tilemap.'));
    }

    final level = appData.gameData.levels[appData.selectedLevel];
    final layer = level.layers[appData.selectedLayer];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('Editing Tilemap for layer "${layer.name}"',
              style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
