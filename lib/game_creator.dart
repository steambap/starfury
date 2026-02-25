import "dart:math";
import 'package:flutter/material.dart' show Colors;

import "scifi_game.dart";
import "hex.dart";
import "cell.dart";
import "tile_type.dart";
import "game_settings.dart";
import "planet.dart";
import "player.dart";
import "unit.dart";
import "name.dart" show planetNames;

const plasticRatio = 1.32471795724474602596;

class GameCreator {
  static const playerColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.brown,
    Colors.cyan,
  ];

  final ScifiGame game;
  late GameSettings gameSettings;
  late Random rand;

  int planetIdx = 0;
  int playerHomeIdx = 0;
  int numOfPlanets = 0;
  List<String> _names = [];

  GameCreator(this.game);

  void create(GameSettings gameSettings) {
    this.gameSettings = gameSettings;
    rand = Random(gameSettings.seed);

    game.g.cells.clear();
    game.g.planets.clear();
    planetIdx = 0;
    playerHomeIdx = 0;
    numOfPlanets = gameSettings.players.length * 7;
    _names = planetNames.toList(growable: false);
    _names.shuffle(rand);

    for (int x = 0; x < gameSettings.mapSize; x++) {
      final col = <Cell>[];
      for (int y = 0; y < gameSettings.mapSize; y++) {
        col.add(Cell(Hex(x, y)));
      }
      game.g.cells.add(col);
    }

    final startPositions = _getStartPositions();
    for (int i = 0; i < gameSettings.players.length; i++) {
      final hex = startPositions[i];
      _homePlanetAtCell(hex);
      final isAI = gameSettings.players[i].isAI;
      game.g.players.add(Player(i, isAI, color: playerColors[i]));
      if (!isAI) {
        game.g.humanPlayerIdx = i;
      }

      final ship = Unit(
        uid: game.g.nextUID(),
        playerNumber: i,
        kind: 0,
        hex: hex,
      );
      game.mapGrid.addShip(ship);
    }

    for (int i = gameSettings.players.length; i < numOfPlanets; i++) {
      final hex = startPositions[i];
      final type =
          PlanetType.values[1 + rand.nextInt(PlanetType.values.length - 1)];
      _planetAtCell(hex, type);
    }

    _assignNames();

    for (int col = 0; col < gameSettings.mapSize; col++) {
      for (int row = 0; row < gameSettings.mapSize; row++) {
        final cell = game.g.cells[col][row];
        if (cell.planet != null) {
          continue;
        }

        final tileNum = rand.nextInt(10);
        if (tileNum < 1) {
          cell.tileType = TileType.nebula;
        } else if (tileNum < 2) {
          cell.tileType = TileType.asteroidField;
        }
      }
    }
  }

  Planet _planetAtCell(Hex center, PlanetType type) {
    final centerCell = game.g.cells[center.x][center.y];
    final planet = Planet(planetIdx, center, type);
    centerCell.planet = planet;
    game.g.planets.add(planet);
    planetIdx += 1;

    return planet;
  }

  Planet _homePlanetAtCell(Hex center) {
    final planet = _planetAtCell(center, PlanetType.terran);
    planet.setHome(playerHomeIdx);
    playerHomeIdx += 1;

    return planet;
  }

  List<Hex> _getStartPositions() {
    const a1 = 1 / plasticRatio;
    const a2 = 1 / (plasticRatio * plasticRatio);
    final pad = rand.nextDouble();
    final positions = <Hex>[];
    final l = gameSettings.mapSize;

    for (int i = 0; i < numOfPlanets; i++) {
      final xi = (pad + i * a1) % 1;
      final yi = (pad + i * a2) % 1;
      final hex = Hex((xi * l).floor(), (yi * l).floor());
      positions.add(hex);
    }

    return positions;
  }

  void _assignNames() {
    for (int i = 0; i < game.g.planets.length; i++) {
      final planet = game.g.planets[i];
      planet.name = _names[i];
    }
  }
}
