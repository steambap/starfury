import 'dart:async';
import "dart:math";

import 'package:flame/components.dart';
import "package:flame/events.dart";
import 'package:flame/extensions.dart';

import 'game_creator.dart';
import 'ship.dart';
import "ship_hull.dart";
import 'scifi_game.dart';
import 'cell.dart';
import "pathfinding.dart";
import "hex.dart";
import "select_control.dart";
import "sector.dart";
import "tile_type.dart";
import "theme.dart" show hexBorderPaint;

// https://www.redblobgames.com/grids/hexagons/#pixel-to-hex
Hex _pixelToHex(Vector2 pixel) {
  final double x = (sqrt(3) / 3 * pixel.x - 1 / 3 * pixel.y) / Hex.size;
  final double y = (2 / 3 * pixel.y) / Hex.size;
  final Hex hex = Hex.cubeRound(Vector3(x, y, -x - y));

  return hex;
}

class MapGrid extends Component with HasGameRef<ScifiGame>, TapCallbacks {
  static final tileSize = Vector2.all(72);

  List<Cell> cells = List.empty();

  /// Hex to cell index
  final Map<int, int> _hexTable = {};
  late final Sprite nebula;
  late final List<Sprite> asteroids;
  late final Sprite gravityRift;

  List<Sector> sectors = [];
  Pathfinding pathfinding = Pathfinding({});
  final List<Ship> shipListAll = [];
  final Map<int, List<Ship>> shipMap = {};
  late SelectControl _selectControl;

  @override
  FutureOr<void> onLoad() {
    _selectControl = SelectControlWaitForInput(game);
    nebula = Sprite(game.images.fromCache("nebula.png"));
    gravityRift = Sprite(game.images.fromCache("gravity_rift.png"));
    final asteroidImg = game.images.fromCache("asteroid.png");
    asteroids = [
      Sprite(asteroidImg, srcPosition: Vector2(0, 0), srcSize: tileSize),
      Sprite(asteroidImg, srcPosition: Vector2(72, 0), srcSize: tileSize),
      Sprite(asteroidImg, srcPosition: Vector2(144, 0), srcSize: tileSize),
    ];
  }

  // Draw all hexagons in one go
  @override
  void render(Canvas canvas) {
    final corners = Hex.zero
        .polygonCorners()
        .map((e) => e.toOffset())
        .toList(growable: false);

    for (final cell in cells) {
      canvas.save();
      canvas.translate(cell.position.x, cell.position.y);

      final ns = cell.hex.getNeighbours();
      for (int i = 0; i < ns.length; i++) {
        canvas.drawLine(
            corners[(11 - i) % 6], corners[(12 - i) % 6], hexBorderPaint);
      }
      // draw tile
      final t = cell.tileType;
      if (t == TileType.gravityRift) {
        gravityRift.render(canvas, size: tileSize, anchor: Anchor.center);
      } else if (t == TileType.nebula) {
        nebula.render(canvas, size: tileSize, anchor: Anchor.center);
      } else if (t == TileType.asteroidField) {
        final index = cell.hex.q % 3;
        asteroids[index].render(canvas, size: tileSize, anchor: Anchor.center);
      }

      canvas.restore();
    }
    super.render(canvas);
  }

  set selectControl(SelectControl s) {
    _selectControl.onStateExit();
    _selectControl = s;
    s.onStateEnter();
  }

  SelectControl get selectControl => _selectControl;

  /// Input block
  void blockSelect() {
    selectControl = SelectControlBlockInput(game);
  }

  /// Wait for input
  void unSelect() {
    selectControl = SelectControlWaitForInput(game);
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    if (cells.isEmpty) {
      return false;
    }
    final radius = Hex.size * (game.currentGameSettings.mapSize + 1) * 2;
    return point.length <= radius;
  }

  @override
  void onTapUp(TapUpEvent event) {
    final hex = _pixelToHex(event.localPosition);

    final cellIndex = _hexTable[hex.toInt()] ?? -1;
    if (cellIndex < 0) {
      unSelect();
      return;
    }
    final cell = cells[cellIndex];
    _selectControl.onCellClick(cell);
  }

  Cell? cellAtPosition(Vector2 localPosition) {
    final hex = _pixelToHex(localPosition);

    final cellIndex = _hexTable[hex.toInt()] ?? -1;
    if (cellIndex < 0) {
      return null;
    }
    return cells[cellIndex];
  }

  void initHexTable() {
    _hexTable.clear();
    for (int i = 0; i < cells.length; i++) {
      final cell = cells[i];
      _hexTable[cell.hex.toInt()] = i;
    }
  }

  FutureOr<void> initMap(GameCreator gc) async {
    cells = gc.cells;
    sectors = gc.sectors;
    initHexTable();

    pathfinding = Pathfinding(_calcEdges());

    await addAll(cells);

    shipListAll.clear();
    shipMap.clear();
    for (final p in game.controller.players) {
      shipMap[p.playerNumber] = [];
      final capitalCell = getCapitalCell(p.playerNumber);
      if (capitalCell == null) {
        continue;
      }
      // spawn a scout
      final scoutHull = p.hulls[0];
      spawnShipAt(capitalCell, p.playerNumber, scoutHull);
    }

    selectControl = SelectControlWaitForInput(game);
  }

  Edges _calcEdges() {
    final Edges edges = {};

    for (final cell in cells) {
      edges[cell] = {};
      final ns = cell.hex.getNeighbours();
      for (final neighbour in ns) {
        final nIndex = _hexTable[neighbour.toInt()] ?? -1;
        if (nIndex < 0) {
          continue;
        }
        final nCell = cells[nIndex];
        final cost = nCell.tileType.cost;
        if (cost != -1) {
          edges[cell]![nCell] = cost;
        }
      }
    }

    return edges;
  }

  moveShip(Ship ship, Cell cell) {
    final prevCell = ship.cell;
    prevCell.ship = null;

    ship.cell = cell;
    List<Cell> fromCells = List.empty();
    if (_selectControl is SelectControlCellSelected) {
      final paths = (_selectControl as SelectControlCellSelected).paths;
      if (paths.containsKey(cell)) {
        fromCells = paths[cell]!;
      }
    }
    ship.moveAnim(cell, fromCells);
    cell.ship = ship;
  }

  Future<void> spawnShipAt(Cell cell, int playerNumber, ShipHull hull) async {
    final ship = Ship(cell, playerNumber, hull);
    cell.ship = ship;

    shipListAll.add(ship);
    shipMap[playerNumber]!.add(ship);

    await add(ship);
  }

  Future<void> createShipAt(Cell cell, int playerNumber, ShipHull hull) async {
    final ship = Ship(cell, playerNumber, hull);
    cell.ship = ship;

    shipListAll.add(ship);
    shipMap[playerNumber]!.add(ship);

    await add(ship);
    ship.setTurnOver();
  }

  Cell? getCapitalCell(int playerNumber) {
    for (final s in sectors) {
      if (s.homePlanet && s.playerNumber == playerNumber) {
        final hex = s.hex;
        final index = _hexTable[hex.toInt()] ?? -1;
        if (index < 0) {
          continue;
        }
        return cells[index];
      }
    }

    return null;
  }

  List<Cell> getShipDeployableCells(int playerNumber) {
    final List<Cell> deployableCells = [];
    for (final cell in cells) {
      if (cell.sector != null) {
        if (cell.sector?.playerNumber == playerNumber) {
          const range = Block(0, 1);
          final cellsInRange = inRange(cell, range);
          for (final cell in cellsInRange) {
            if (cell.ship == null) {
              deployableCells.add(cell);
            }
          }
        }
      }
    }

    return deployableCells;
  }

  List<Cell> playerPlanetCells(int playerNumber) {
    final List<Cell> playerCells = [];
    for (final cell in cells) {
      if (cell.sector != null && cell.sector!.playerNumber == playerNumber) {
        playerCells.add(cell);
      }
    }

    return playerCells;
  }

  List<Cell> humanPlayerPlanetCells() {
    return playerPlanetCells(game.controller.getHumanPlayerNumber());
  }

  List<Cell> inRange(Cell center, Block range) {
    final List<Cell> cellsInRange = [];
    if (range.x == 0) {
      cellsInRange.add(center);
    }
    if (range.y == 0) {
      return cellsInRange;
    }
    int i = max(1, range.x);
    for (; i <= range.y; i++) {
      final ring = center.hex.cubeRing(i);
      for (final hex in ring) {
        final index = _hexTable[hex.toInt()] ?? -1;
        if (index < 0) {
          continue;
        }
        final cell = cells[index];
        cellsInRange.add(cell);
      }
    }

    return cellsInRange;
  }

  List<Cell> findAttackableCells(Cell originalCell, Block range) {
    final attackingPlayerNumber = originalCell.ship?.state.playerNumber ?? -1;
    final List<Cell> attackableCells = [];
    final cellsInRange = inRange(originalCell, range);
    for (final cell in cellsInRange) {
      if (cell.ship != null &&
          cell.ship!.state.playerNumber != attackingPlayerNumber) {
        attackableCells.add(cell);
      } else if (cell.sector != null &&
          cell.sector!.attackable(attackingPlayerNumber)) {
        attackableCells.add(cell);
      }
    }

    return attackableCells;
  }

  void removeShip(Ship ship) {
    shipListAll.remove(ship);
    shipMap[ship.state.playerNumber]!.remove(ship);
  }

  Map<String, dynamic> toJson() {
    return {
      "cells": cells.map((e) => e.toJson()).toList(),
      "sectors": sectors.map((e) => e.toJson()).toList(),
      // ships goes here
    };
  }
}
