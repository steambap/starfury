import "package:flame/components.dart";

import "action.dart";
import "scifi_game.dart";
import "cell.dart";
import 'ship.dart';
import 'ship_hull.dart';
import 'building.dart';

sealed class SelectControl {
  final ScifiGame game;

  SelectControl(this.game);

  void onCellClick(Cell cell) {}

  void onStateEnter() {}

  void onStateExit() {}
}

class SelectControlBlockInput extends SelectControl {
  SelectControlBlockInput(super.game);
}

class SelectControlWaitForInput extends SelectControl {
  SelectControlWaitForInput(super.game);

  @override
  void onCellClick(Cell cell) {
    if (cell.ship != null) {
      game.mapGrid.selectControl = SelectControlCellSelected(game, cell);
    } else if (cell.planet != null) {
      game.mapGrid.selectControl = SelectControlPlanet(game, cell);
    }
  }
}

/// Base class for selecting a cell or planet or ship
class SelectControlHex extends SelectControl {
  SelectControlHex(super.game);

  @override
  void onCellClick(Cell cell) {
    if (cell.ship != null) {
      game.mapGrid.selectControl = SelectControlCellSelected(game, cell);
    } else if (cell.planet != null) {
      game.mapGrid.selectControl = SelectControlPlanet(game, cell);
    } else {
      game.mapGrid.selectControl = SelectControlWaitForInput(game);
    }
  }
}

class SelectControlCellSelected extends SelectControlHex {
  final Cell cell;
  late final Ship? ship;
  Map<Cell, List<Cell>> paths = {};
  Set<Cell> attackableCells = {};

  SelectControlCellSelected(super.game, this.cell);

  @override
  void onCellClick(Cell cell) {
    if (this.cell == cell) {
      if (cell.planet != null) {
        game.mapGrid.selectControl = SelectControlPlanet(game, cell);
      }

      return;
    }

    if (paths.containsKey(cell)) {
      game.mapGrid.moveShip(ship!, cell);
      game.mapGrid.selectControl = SelectControlWaitForInput(game);
    } else if (attackableCells.contains(cell)) {
      game.combatResolver.resolve(ship!, cell);
      game.mapGrid.selectControl = SelectControlWaitForInput(game);
    } else {
      super.onCellClick(cell);
    }
  }

  @override
  void onStateEnter() {
    if (cell.ship != null) {
      ship = cell.ship;
      final shipOwner = ship?.state.playerNumber ?? -1;
      final isOwnerHuman = game.controller.getHumanPlayerNumber() == shipOwner;
      game.shipCommand.updateRender(ship);
      game.mapDeploy.minimize();
      if (isOwnerHuman) {
        paths =
            game.mapGrid.pathfinding.findAllPath(cell, cell.ship!.movePoint());
        if (ship!.canAttack()) {
          final maxRange = ship!.hull.attackRange();
          attackableCells = game.mapGrid
              .findAttackableCells(cell, Block(1, maxRange))
              .toSet();
        }
      }
    }
    for (final cell in paths.keys) {
      final fromCells = paths[cell]!;
      final moveCost = fromCells.fold(0, (previousValue, element) {
        return previousValue + element.tileType.cost;
      });
      final movePoint = ship!.movePoint() - moveCost;
      cell.markAsHighlight(movePoint);
    }
    for (final cell in attackableCells) {
      cell.markAsTarget();
    }
  }

  @override
  void onStateExit() {
    game.shipCommand.updateRender(null);
    for (final cell in paths.keys) {
      cell.unmark();
    }
    for (final cell in attackableCells) {
      cell.unmark();
    }
  }
}

class SelectControlPlanet extends SelectControlHex {
  final Cell cell;
  SelectControlPlanet(super.game, this.cell);

  @override
  void onCellClick(Cell cell) {
    if (this.cell == cell) {
      if (cell.ship != null) {
        game.mapGrid.selectControl = SelectControlCellSelected(game, cell);
      }

      return;
    }

    super.onCellClick(cell);
  }

  @override
  void onStateEnter() {
    game.hudPlanet.planet = cell.planet;
    game.world.renderPlanetMenu(cell.planet);
    game.mapDeploy.minimize();
  }

  @override
  void onStateExit() {
    game.hudPlanet.planet = null;
    game.world.renderPlanetMenu(null);
  }
}

class SelectControlCreateShip extends SelectControl {
  final Set<Cell> cells = {};
  final ShipHull hull;
  SelectControlCreateShip(super.game, this.hull);

  @override
  void onCellClick(Cell cell) {
    if (cells.contains(cell)) {
      game.resourceController
          .createShip(cell, game.controller.getHumanPlayerNumber(), hull);
    }
    game.mapGrid.selectControl = SelectControlWaitForInput(game);
  }

  @override
  void onStateEnter() {
    final deployableCells = game.mapGrid
        .getShipDeployableCells(game.controller.getHumanPlayerNumber());
    for (final cell in deployableCells) {
      cells.add(cell);
      cell.markAsHighlight();
    }
  }

  @override
  void onStateExit() {
    for (final cell in cells) {
      cell.unmark();
    }
  }
}

class SelectControlWaitForAction extends SelectControl {
  final Action action;
  final Cell cell;
  late final List<Cell> targets;
  SelectControlWaitForAction(this.action, this.cell, super.game);

  @override
  void onCellClick(Cell cell) {
    if (targets.contains(cell)) {
      action.execute(this.cell.ship!, cell);
    }
    game.mapGrid.selectControl = SelectControlWaitForInput(game);
  }

  @override
  void onStateEnter() {
    targets = action.getTargets(game.mapGrid, cell);
    for (final cell in targets) {
      cell.markAsTarget();
    }
  }

  @override
  void onStateExit() {
    for (final cell in targets) {
      cell.unmark();
    }
  }
}

class SelectControlAddBuilding extends SelectControl {
  final Set<Cell> cells = {};
  final Building building;
  SelectControlAddBuilding(this.building, super.game);

  @override
  void onCellClick(Cell cell) {
    if (cells.contains(cell)) {
      final playerNumber = game.controller.getHumanPlayerNumber();
      game.resourceController.addBuilding(playerNumber, cell.planet!, building);
    }
    game.mapGrid.selectControl = SelectControlWaitForInput(game);
  }

  @override
  void onStateEnter() {
    final playerNumber = game.controller.getHumanPlayerNumber();
    final deployableCells = game.mapGrid.humanPlayerPlanetCells();
    for (final cell in deployableCells) {
      if (game.resourceController
          .canAddBuilding(playerNumber, cell.planet!, building)) {
        cells.add(cell);
        cell.markAsHighlight();
      }
    }
  }

  @override
  void onStateExit() {
    for (final cell in cells) {
      cell.unmark();
    }
  }
}
