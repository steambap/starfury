import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

import 'scifi_game.dart';
import "theme.dart" show text16, buttonPaintLayer, buttonHoverPaintLayer;

class HudNextTurnBtn extends PositionComponent
    with HasGameRef<ScifiGame>, TapCallbacks, HoverCallbacks {
  static final buttonSize = Vector2(100, 32);
  final RectangleComponent rect =
      RectangleComponent(size: buttonSize, paintLayers: buttonPaintLayer);
  final TextComponent buttonText = TextComponent(
      text: "Next Turn", anchor: Anchor.center, textRenderer: text16);
  HudNextTurnBtn() : super(size: buttonSize);

  @override
  FutureOr<void> onLoad() {
    position =
        Vector2(game.size.x - buttonSize.x - 8, game.size.y - buttonSize.y - 8);

    buttonText.position = buttonSize / 2;

    addAll([rect, buttonText]);
  }

  @override
  void onHoverEnter() {
    rect.paintLayers = buttonHoverPaintLayer;
  }

  @override
  void onHoverExit() {
    rect.paintLayers = buttonPaintLayer;
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (game.controller.isAITurn()) {
      return;
    }
    game.controller.endTurn();
  }
}
