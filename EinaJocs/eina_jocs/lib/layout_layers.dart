import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_data.dart';
import 'game_layer.dart';
import 'titled_text_filed.dart';

class LayoutLayers extends StatefulWidget {
  const LayoutLayers({super.key});

  @override
  LayoutLayersState createState() => LayoutLayersState();
}

class LayoutLayersState extends State<LayoutLayers> {
  late TextEditingController nameController;
  late TextEditingController xController;
  late TextEditingController yController;
  late TextEditingController depthController;
  String tilesSheetFile = "";
  late TextEditingController tileWidthController;
  late TextEditingController tileHeightController;
  late TextEditingController tilemapWidthController;
  late TextEditingController tilemapHeightController;
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    xController = TextEditingController();
    yController = TextEditingController();
    depthController = TextEditingController();
    tileWidthController = TextEditingController();
    tileHeightController = TextEditingController();
    tilemapWidthController = TextEditingController();
    tilemapHeightController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appData = Provider.of<AppData>(context, listen: false);
      _updateForm(appData);
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    xController.dispose();
    yController.dispose();
    depthController.dispose();
    tileWidthController.dispose();
    tileHeightController.dispose();
    tilemapWidthController.dispose();
    tilemapHeightController.dispose();
    super.dispose();
  }

  bool isVisible = true; // Estat local per al switch

  void _updateForm(AppData appData) {
    if (appData.selectedLevel != -1 && appData.selectedLayer != -1) {
      final selectedLayer = appData
          .gameData.levels[appData.selectedLevel].layers[appData.selectedLayer];
      nameController.text = selectedLayer.name;
      xController.text = selectedLayer.x.toString();
      yController.text = selectedLayer.y.toString();
      depthController.text = selectedLayer.depth.toString();
      tilesSheetFile = selectedLayer.tilesSheetFile;
      tileWidthController.text = selectedLayer.tilesWidth.toString();
      tileHeightController.text = selectedLayer.tilesHeight.toString();
      tilemapWidthController.text = selectedLayer.tileMap[0].length.toString();
      tilemapHeightController.text = selectedLayer.tileMap.length.toString();
      isVisible = selectedLayer.visible;
    } else {
      nameController.clear();
      xController.clear();
      yController.clear();
      depthController.clear();
      tilesSheetFile = "";
      tileWidthController.clear();
      tileHeightController.clear();
      tilemapWidthController.clear();
      tilemapHeightController.clear();
      isVisible = true;
    }
  }

  void _addLayer(AppData appData) {
    if (appData.selectedLevel == -1) return;

    int tileMapWidth = int.tryParse(tilemapWidthController.text) ?? 32;
    int tileMapHeight = int.tryParse(tilemapHeightController.text) ?? 32;

    final newLayer = GameLayer(
        name: nameController.text,
        x: int.tryParse(xController.text) ?? 0,
        y: int.tryParse(yController.text) ?? 0,
        depth: int.tryParse(depthController.text) ?? 0,
        tilesSheetFile: tilesSheetFile,
        tilesWidth: int.tryParse(tileWidthController.text) ?? 32,
        tilesHeight: int.tryParse(tileHeightController.text) ?? 32,
        tileMap:
            List.generate(tileMapHeight, (_) => List.filled(tileMapWidth, -1)),
        visible: isVisible);

    appData.gameData.levels[appData.selectedLevel].layers.add(newLayer);
    appData.selectedLayer = -1;
    tilesSheetFile = "";
    _updateForm(appData);
    appData.update();
  }

  void _updateLayer(AppData appData) {
    if (appData.selectedLevel != -1 && appData.selectedLayer != -1) {
      final layers = appData.gameData.levels[appData.selectedLevel].layers;
      final GameLayer oldLayer = layers[appData.selectedLayer];

      int newWidth = int.tryParse(tilemapWidthController.text) ?? 32;
      int newHeight = int.tryParse(tilemapHeightController.text) ?? 16;

      List<List<int>> newTileMap = List.generate(newHeight, (y) {
        return List.generate(newWidth, (x) {
          if (y < oldLayer.tileMap.length && x < oldLayer.tileMap[0].length) {
            return oldLayer.tileMap[y][x];
          }
          return -1;
        });
      });

      layers[appData.selectedLayer] = GameLayer(
          name: nameController.text,
          x: int.tryParse(xController.text) ?? 0,
          y: int.tryParse(yController.text) ?? 0,
          depth: int.tryParse(depthController.text) ?? 0,
          tilesSheetFile: tilesSheetFile,
          tilesWidth: int.tryParse(tileWidthController.text) ?? 0,
          tilesHeight: int.tryParse(tileHeightController.text) ?? 0,
          tileMap: newTileMap,
          visible: isVisible);

      appData.update();
    }
  }

  void _deleteLayer(AppData appData) {
    if (appData.selectedLevel != -1 && appData.selectedLayer != -1) {
      appData.gameData.levels[appData.selectedLevel].layers
          .removeAt(appData.selectedLayer);
      appData.selectedLayer = -1;
      _updateForm(appData);
      appData.update();
    }
  }

  void _selectLayer(AppData appData, int index, bool isSelected) {
    appData.selectedLayer = isSelected ? -1 : index;
    _updateForm(appData);
    appData.update();
  }

  void _onReorder(AppData appData, int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final layers = appData.gameData.levels[appData.selectedLevel].layers;
    final int selectedIndex = appData.selectedLayer;

    final layer = layers.removeAt(oldIndex);
    layers.insert(newIndex, layer);

    if (selectedIndex == oldIndex) {
      appData.selectedLayer = newIndex;
    } else if (selectedIndex > oldIndex && selectedIndex <= newIndex) {
      appData.selectedLayer -= 1;
    } else if (selectedIndex < oldIndex && selectedIndex >= newIndex) {
      appData.selectedLayer += 1;
    } else {
      appData.selectedLayer = selectedIndex;
    }

    appData.update();

    if (kDebugMode) {
      print(
          "Updated layer order: ${appData.gameData.levels[appData.selectedLevel].layers.map((layer) => layer.name).join(', ')}");
      print("Selected layer remains at index: ${appData.selectedLayer}");
    }
  }

  Future<void> _pickTilesSheet(AppData appData) async {
    tilesSheetFile = await appData.pickImageFile();
    appData.update();
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    if (appData.selectedLevel == -1) {
      return const Center(
        child: Text(
          'No level selected',
          style: TextStyle(fontSize: 16.0, color: CupertinoColors.systemGrey),
        ),
      );
    }

    final level = appData.gameData.levels[appData.selectedLevel];
    final layers = level.layers;

    final bool isFormFilled = nameController.text.isNotEmpty &&
        xController.text.isNotEmpty &&
        yController.text.isNotEmpty &&
        depthController.text.isNotEmpty &&
        tilesSheetFile != "" &&
        tileWidthController.text.isNotEmpty &&
        tileHeightController.text.isNotEmpty &&
        tilemapWidthController.text.isNotEmpty &&
        tilemapHeightController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Editing Layers for level "${level.name}"',
            style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
            child: layers.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      '(No layers defined)',
                      style: TextStyle(
                          fontSize: 12.0, color: CupertinoColors.systemGrey),
                    ),
                  )
                : CupertinoScrollbar(
                    controller: scrollController,
                    child: Localizations.override(
                      context: context,
                      delegates: [
                        DefaultMaterialLocalizations
                            .delegate, // Add Material Localizations
                        DefaultWidgetsLocalizations.delegate,
                      ],
                      child: ReorderableListView.builder(
                        //controller: scrollController,
                        itemCount: layers.length,
                        onReorder: (oldIndex, newIndex) =>
                            _onReorder(appData, oldIndex, newIndex),
                        itemBuilder: (context, index) {
                          final isSelected = (index == appData.selectedLayer);
                          final layer = appData.gameData
                              .levels[appData.selectedLevel].layers[index];
                          String subtitle =
                              "${layer.depth} - ${layer.tilesSheetFile}";
                          return GestureDetector(
                              key: ValueKey(layers[index]), // Reorder value key
                              onTap: () {
                                _selectLayer(appData, index, isSelected);
                              },
                              child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 8),
                                  color: isSelected
                                      ? CupertinoColors.systemBlue
                                          .withOpacity(0.2)
                                      : CupertinoColors.systemBackground,
                                  child: Row(children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            layers[index].name,
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            subtitle,
                                            style: const TextStyle(
                                              fontSize: 12.0,
                                              color: CupertinoColors.systemGrey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ])));
                        },
                      ),
                    ),
                  )),
        const SizedBox(height: 8),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              (appData.selectedLayer == -1) ? 'Add layer:' : 'Modify layer:',
              style:
                  const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
            )),
        const SizedBox(height: 8),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(children: [
              Expanded(
                  child: TitledTextfield(
                title: "Layer name",
                controller: nameController,
                onChanged: (_) => setState(() {}),
              )),
              const SizedBox(width: 8),
              Column(children: [
                Text(
                  'Visible',
                  style: const TextStyle(fontSize: 14.0),
                ),
                Transform.scale(
                    scale: 0.65,
                    child: CupertinoSwitch(
                      value: isVisible,
                      onChanged: (bool value) {
                        setState(() {
                          isVisible = value;
                        });
                      },
                    ))
              ]),
            ])),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Expanded(
                child: TitledTextfield(
                  title: 'X position (px)',
                  controller: xController,
                  placeholder: '0',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TitledTextfield(
                  title: 'Y position (px)',
                  controller: yController,
                  placeholder: '0',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TitledTextfield(
                  title: 'Depth (z-index)',
                  controller: depthController,
                  placeholder: '0',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'Tiles image:',
              style:
                  const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
            )),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  tilesSheetFile == "" ? "No file selected" : tilesSheetFile,
                  style: const TextStyle(
                      fontSize: 12.0, color: CupertinoColors.systemGrey),
                ),
              ),
              CupertinoButton.filled(
                sizeStyle: CupertinoButtonSize.small,
                borderRadius: BorderRadius.all(Radius.circular(5)),
                child: const Text(
                  "Choose File",
                  style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _pickTilesSheet(appData),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Expanded(
                child: TitledTextfield(
                  title: 'Tile width (px)',
                  controller: tileWidthController,
                  placeholder: '32',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TitledTextfield(
                  title: 'Tile height (px)',
                  controller: tileHeightController,
                  placeholder: '32',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Expanded(
                child: TitledTextfield(
                  title: 'Tilemap width (tiles)',
                  controller: tilemapWidthController,
                  placeholder: '32',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TitledTextfield(
                  title: 'Tilemap height (tiles)',
                  controller: tilemapHeightController,
                  placeholder: '16',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (appData.selectedLayer != -1) ...[
              CupertinoButton.filled(
                sizeStyle: CupertinoButtonSize.small,
                borderRadius: BorderRadius.all(Radius.circular(5)),
                onPressed: isFormFilled ? () => _updateLayer(appData) : null,
                child: const Text('Update'),
              ),
              CupertinoButton(
                sizeStyle: CupertinoButtonSize.small,
                borderRadius: BorderRadius.all(Radius.circular(5)),
                color: CupertinoColors.destructiveRed,
                onPressed: () => _deleteLayer(appData),
                child:
                    const Text('Delete', style: TextStyle(color: Colors.white)),
              ),
            ] else
              CupertinoButton.filled(
                sizeStyle: CupertinoButtonSize.small,
                borderRadius: BorderRadius.all(Radius.circular(5)),
                onPressed: isFormFilled ? () => _addLayer(appData) : null,
                child: const Text('Add Layer'),
              ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
