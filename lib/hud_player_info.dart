import 'dart:async';
import 'package:flame/components.dart';

import 'scifi_game.dart';
import "theme.dart" show text16;

class HudPlayerInfo extends PositionComponent with HasGameRef<ScifiGame> {
  final TextComponent _energyLabel = TextComponent(textRenderer: text16);
  HudPlayerInfo();

  @override
  FutureOr<void> onLoad() {
    position = Vector2(8, 8);

    add(_energyLabel);
  }

  void updateRender() {
    final playerState = game.controller.getHumanPlayerState();
    final t = game.controller.gameState.turn;
    final energyIncome = game.resourceController.humanPlayerEnergyIncome();
    _energyLabel.text = "\$${playerState.energy}($energyIncome) turn $t";
  }
}
