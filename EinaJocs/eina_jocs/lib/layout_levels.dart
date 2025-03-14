import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_data.dart';
import 'game_level.dart';
import 'titled_text_filed.dart';

class LayoutLevels extends StatefulWidget {
  const LayoutLevels({super.key});

  @override
  LayoutLevelsState createState() => LayoutLevelsState();
}

class LayoutLevelsState extends State<LayoutLevels> {
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    descriptionController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appData = Provider.of<AppData>(context, listen: false);
      _updateForm(appData);
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _updateForm(AppData appData) {
    if (appData.selectedLevel != -1) {
      final selectedLevel = appData.gameData.levels[appData.selectedLevel];
      nameController.text = selectedLevel.name;
      descriptionController.text = selectedLevel.description;
    } else {
      nameController.clear();
      descriptionController.clear();
    }
  }

  void _addLevel(AppData appData) {
    final newLevel = GameLevel(
      name: nameController.text,
      description: descriptionController.text,
      layers: [],
      zones: [],
      sprites: [],
    );

    appData.gameData.levels.add(newLevel);
    appData.selectedLevel = -1;
    _updateForm(appData);
    appData.update();
  }

  void _updateLevel(AppData appData) {
    if (appData.selectedLevel != -1) {
      appData.gameData.levels[appData.selectedLevel] = GameLevel(
        name: nameController.text,
        description: descriptionController.text,
        layers: appData.gameData.levels[appData.selectedLevel].layers,
        zones: appData.gameData.levels[appData.selectedLevel].zones,
        sprites: appData.gameData.levels[appData.selectedLevel].sprites,
      );
      appData.update();
    }
  }

  void _deleteLevel(AppData appData) {
    if (appData.selectedLevel != -1) {
      appData.gameData.levels.removeAt(appData.selectedLevel);
      appData.selectedLevel = -1;
      _updateForm(appData);
      appData.update();
    }
  }

  void _selectLevel(AppData appData, int index, bool isSelected) {
    appData.selectedLevel = isSelected ? -1 : index;
    appData.selectedLayer = -1;
    appData.selectedZone = -1;
    appData.selectedSprite = -1;
    _updateForm(appData);
    appData.update();
  }

  void _onReorder(AppData appData, int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final levels = appData.gameData.levels;
    final int selectedIndex = appData.selectedLevel;

    final item = levels.removeAt(oldIndex);
    levels.insert(newIndex, item);

    if (selectedIndex == oldIndex) {
      appData.selectedLevel = newIndex;
    } else if (selectedIndex > oldIndex && selectedIndex <= newIndex) {
      appData.selectedLevel -= 1;
    } else if (selectedIndex < oldIndex && selectedIndex >= newIndex) {
      appData.selectedLevel += 1;
    } else {
      appData.selectedLevel = selectedIndex;
    }

    appData.update();

    if (kDebugMode) {
      print(
          "Updated level order: ${appData.gameData.levels.map((level) => level.name).join(', ')}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final levels = appData.gameData.levels;

    bool isFormFilled =
        nameController.text.isNotEmpty && descriptionController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Game levels:',
            style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
            child: levels.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      '(No levels defined)',
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
                        itemCount: levels.length,
                        onReorder: (oldIndex, newIndex) =>
                            _onReorder(appData, oldIndex, newIndex),
                        itemBuilder: (context, index) {
                          final isSelected = (index == appData.selectedLevel);
                          return GestureDetector(
                            key: ValueKey(levels[index]), // Reorder value key
                            onTap: () {
                              _selectLevel(appData, index, isSelected);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
                              color: isSelected
                                  ? CupertinoColors.systemBlue.withOpacity(0.2)
                                  : CupertinoColors.systemBackground,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          levels[index].name,
                                          style: TextStyle(
                                            fontSize: 14.0,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          levels[index].description,
                                          style: const TextStyle(
                                            fontSize: 12.0,
                                            color: CupertinoColors.systemGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  )),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            (appData.selectedLevel == -1) ? 'New level:' : 'Modify level:',
            style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TitledTextfield(
            title: 'Level name',
            controller: nameController,
            onChanged: (_) => setState(() {}), // Per actualitzar el botó
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TitledTextfield(
            title: 'Level description',
            controller: descriptionController,
            onChanged: (_) => setState(() {}), // Per actualitzar el botó
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (appData.selectedLevel != -1) ...[
              CupertinoButton.filled(
                sizeStyle: CupertinoButtonSize.small,
                borderRadius: BorderRadius.all(Radius.circular(5)),
                onPressed: isFormFilled ? () => _updateLevel(appData) : null,
                child: const Text('Update'),
              ),
              CupertinoButton(
                sizeStyle: CupertinoButtonSize.small,
                borderRadius: BorderRadius.all(Radius.circular(5)),
                color: CupertinoColors.destructiveRed,
                onPressed: () => _deleteLevel(appData),
                child:
                    const Text('Delete', style: TextStyle(color: Colors.white)),
              ),
            ] else
              CupertinoButton.filled(
                sizeStyle: CupertinoButtonSize.small,
                borderRadius: BorderRadius.all(Radius.circular(5)),
                onPressed: isFormFilled ? () => _addLevel(appData) : null,
                child: const Text('Add Level'),
              ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
