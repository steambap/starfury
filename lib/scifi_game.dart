import 'package:flame/events.dart';
import 'package:flame/game.dart';

import 'hud_next_turn_btn.dart';
import 'hud_player_info.dart';
import 'game_state_controller.dart';
import 'game_creator.dart';
import 'map_grid.dart';
import "game_settings.dart";
import "resource_controller.dart";
import "ship_data.dart";
import 'hud_unit_panel.dart';

class ScifiGame extends FlameGame with HasKeyboardHandlerComponents {
  final MapGrid mapGrid = MapGrid();
  final GameCreator gameCreator = GameCreator();
  late GameSettings currentGameSettings;
  late final GameStateController gameStateController;
  late final ResourceController resourceController;
  late final ShipDataController shipDataController;
  final HudPlayerInfo playerInfo = HudPlayerInfo();
  final HudNextTurnBtn nextTurnBtn = HudNextTurnBtn();
  final HudShipCreatePanel shipCreatePanel = HudShipCreatePanel();

  ScifiGame() {
    gameStateController = GameStateController(this);
    resourceController = ResourceController(this);
    shipDataController = ShipDataController(this);
  }

  @override
  Future<void> onLoad() async {
    await Future.wait([
      images.loadAllImages(),
      shipDataController.loadData(),
    ]);

    await world.add(mapGrid);

    camera.viewport.addAll([playerInfo, nextTurnBtn, shipCreatePanel]);

    final s = GameSettings(0);
    currentGameSettings = s;
    s.players = gameCreator.getTestPlayers(s);
    final cells = gameCreator.create(s);
    mapGrid.initMap(cells);

    gameStateController.startGame(s.players);
  }
}
