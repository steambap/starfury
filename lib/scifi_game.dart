import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import "scifi_world.dart";
import 'hud_next_turn_btn.dart';
import 'hud_player_info.dart';
import 'game_state_controller.dart';
import 'game_creator.dart';
import 'map_grid.dart';
import "game_settings.dart";
import "resource_controller.dart";
import 'hud_ship_cmd.dart';
import "hud_planet.dart";
import "hud_map_deploy.dart";
import "ai/ai_controller.dart";
import "combat_resolver.dart";

class ScifiGame extends FlameGame<ScifiWorld> with HasKeyboardHandlerComponents {
  final MapGrid mapGrid = MapGrid();
  final GameCreator gameCreator = GameCreator();
  late GameSettings currentGameSettings;
  late final GameStateController controller;
  late final ResourceController resourceController;
  late final AIController aiController;
  late final CombatResolver combatResolver = CombatResolver(this);
  final HudPlayerInfo playerInfo = HudPlayerInfo();
  final HudNextTurnBtn nextTurnBtn = HudNextTurnBtn();
  final HudPlanet hudPlanet = HudPlanet();
  final HudMapDeploy mapDeploy = HudMapDeploy();
  final HudShipCommand shipCommand = HudShipCommand();
  final RouterComponent router = RouterComponent(
    routes: {
      "placeholder": Route(() => PositionComponent()),
    },
    initialRoute: "placeholder"
  );

  ScifiGame(): super(world: ScifiWorld()) {
    controller = GameStateController(this);
    resourceController = ResourceController(this);
    aiController = AIController(this);
  }

  @override
  Future<void> onLoad() async {
    await images.loadAllImages();

    await world.add(mapGrid);
    camera.viewport.addAll([playerInfo, nextTurnBtn, mapDeploy, hudPlanet, shipCommand, router]);

    final s = GameSettings(0);
    currentGameSettings = s;
    s.players = gameCreator.getTestPlayers(s);
    gameCreator.create(s);

    controller.initGame(s.players);
    mapGrid.initMap(gameCreator);
    controller.startGame();
  }
}
