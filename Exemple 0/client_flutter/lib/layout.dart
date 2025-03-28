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
    // Preload image assets into cache
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final appData = Provider.of<AppData>(context, listen: false);
      await appData.loadMapFromJson();
      await appData.getImage("images/tanks1.png");
    });
  }

  // Tractar què passa quan el jugador apreta una tecla
  void _onKeyEvent(KeyEvent event, AppData appData) {
    String key = event.logicalKey.keyLabel.toLowerCase();

    if (key == " ") {
      key == key;
    } else if (key.contains(" ")) {
      key = key.split(" ")[1];
      print(key);
    } else {
      return;
    }

    if (event is KeyDownEvent) {
      _pressedKeys.add(key);
      (key);
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(key);
    }

    // Enviar la direcció escollida pel jugador al servidor
    var direction = _getDirectionFromKeys();
    var shoot = _getShootBoolean();
    appData.sendMessage(jsonEncode({"type": "direction", "value": direction}));
    appData.sendMessage(jsonEncode({"type": "shoot", "value": shoot}));
  }

  String _getDirectionFromKeys() {
    bool up = _pressedKeys.contains("up");
    bool down = _pressedKeys.contains("down");
    bool left = _pressedKeys.contains("left");
    bool right = _pressedKeys.contains("right");

    // if (up && left) return "upLeft";
    // if (up && right) return "upRight";
    // if (down && left) return "downLeft";
    // if (down && right) return "downRight";
    if (up) return "up";
    if (down) return "down";
    if (left) return "left";
    if (right) return "right";

    return "none";
  }

  bool _getShootBoolean() {
    bool shoot = _pressedKeys.contains(" ");

    return shoot;
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
            child: CustomPaint(
              painter: CanvasPainter(appData),
              child: Container(),
            ),
          ),
        ),
      ),
    );
  }
}
