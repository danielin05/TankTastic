import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'app_data.dart';
import 'game_data.dart';
import 'titled_text_filed.dart';

class LayoutGame extends StatefulWidget {
  const LayoutGame({super.key});

  @override
  LayoutGameState createState() => LayoutGameState();
}

class LayoutGameState extends State<LayoutGame> {
  late TextEditingController nameController;

  @override
  void initState() {
    super.initState();
    final appData = Provider.of<AppData>(context, listen: false);
    nameController = TextEditingController(text: appData.gameData.name);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  String _shortenFilePath(String path, {int maxLength = 35}) {
    if (path.length <= maxLength) return path;

    int keepLength =
        (maxLength / 2).floor(); // Part a mantenir a l'inici i al final
    return "${path.substring(0, keepLength)}...${path.substring(path.length - keepLength)}";
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final ScrollController scrollController = ScrollController();

    if (nameController.text != appData.gameData.name) {
      nameController.text = appData.gameData.name;
      nameController.selection =
          TextSelection.collapsed(offset: nameController.text.length);
    }

    return SizedBox.expand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Game settings:',
              style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: CupertinoScrollbar(
              controller: scrollController,
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TitledTextfield(
                      title: 'Game name',
                      controller: nameController,
                      onChanged: (value) {
                        setState(() {
                          appData.gameData = GameData(
                            name: value,
                            levels: appData.gameData.levels,
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Text("Project path:",
                        style: TextStyle(
                          fontSize: 16.0,
                        )),
                    Text(
                      appData.filePath.isEmpty
                          ? "Project path not set"
                          : _shortenFilePath(appData.filePath),
                      style: TextStyle(
                        fontSize: 14.0,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text("File name:",
                        style: TextStyle(
                          fontSize: 16.0,
                        )),
                    Text(
                      appData.fileName.isEmpty
                          ? "File name not set"
                          : appData.fileName,
                      style: TextStyle(
                        fontSize: 14.0,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CupertinoButton.filled(
                  sizeStyle: CupertinoButtonSize.small,
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                  onPressed: () {
                    appData.loadGame();
                  },
                  child: const Text('Load folder'),
                ),
                CupertinoButton.filled(
                  sizeStyle: CupertinoButtonSize.small,
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                  onPressed: () {
                    appData.saveGame();
                  },
                  child: Text('Save'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
