import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app_data.dart';
import 'canvas_painter.dart';

class Layout extends StatefulWidget {
  const Layout({super.key});

  @override
  State<Layout> createState() => _LayoutState();
}

class _LayoutState extends State<Layout> {
  final FocusNode _focusNode = FocusNode();
  final Set<String> _pressedKeys = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final appData = Provider.of<AppData>(context, listen: false);
      await appData.loadMapFromJson();
      await appData.getImage("images/tanks1.png");
      await appData.getImage("images/tanks2.png");
      await appData.getImage("images/tanks3.png");
      await appData.getImage("images/tanks4.png");
      await appData.getImage("sprites/projectile.png");
    });
  }

  void _onKeyEvent(KeyEvent event, AppData appData) {
    String key = event.logicalKey.keyLabel.toLowerCase();

    if (key == " ") {
      key = "space";
    } else if (key.contains(" ")) {
      key = key.split(" ")[1];
    } else {
      return;
    }

    if (event is KeyDownEvent) {
      _pressedKeys.add(key);
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(key);
    }

    var direction = _getDirectionFromKeys();
    if (direction != "none") {
      final player = appData.playerData;
      if (player != null) {
        double x = player["x"];
        double y = player["y"];
        if (!appData.willCollide(x, y, direction)) {
          appData.sendMessage(
              jsonEncode({"type": "direction", "value": direction}));
        }
      }
    }

    if (event is KeyDownEvent && key == "space") {
      appData.sendMessage(jsonEncode({"type": "shoot", "value": true}));
    }
  }

  String _getDirectionFromKeys() {
    bool up = _pressedKeys.contains("up");
    bool down = _pressedKeys.contains("down");
    bool left = _pressedKeys.contains("left");
    bool right = _pressedKeys.contains("right");

    if (up) return "up";
    if (down) return "down";
    if (left) return "left";
    if (right) return "right";

    return "none";
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);

    return CupertinoPageScaffold(
      child: SafeArea(
        child: Container(
          color: CupertinoColors.systemGrey5,
          child: KeyboardListener(
            focusNode: _focusNode,
            autofocus: true,
            onKeyEvent: (KeyEvent event) {
              _onKeyEvent(event, appData);
            },
            child: Center(
              child: SizedBox(
                width: 1024,
                height: 1024,
                child: CustomPaint(
                  painter: CanvasPainter(appData),
                  child: Container(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
