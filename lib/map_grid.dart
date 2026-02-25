import 'dart:async';
import 'dart:math';
import 'dart:ui' show Picture, PictureRecorder;
import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';

import 'scifi_game.dart';
import 'cell.dart';
import "hex.dart";
import 'ship.dart';
import 'unit.dart';
import 'select_control.dart';
import 'styles.dart';
import 'game_settings.dart';

class _CellItem {
  final Cell cell;
  final int priority;

  _CellItem(this.cell, this.priority);
}

class AStarInfo {
  final List<Cell> path;
  final int cost;

  AStarInfo(this.path, this.cost);

  static AStarInfo empty() => AStarInfo([], 0);
}

class MapGrid extends Component
    with HasGameReference<ScifiGame>, TapCallbacks, HasCollisionDetection {
  static const double horiz = 3 / 2 * Hex.size;
  static final double vert = sqrt(3) * Hex.size;
  static const _cornerIndices = [
    (5, 0),
    (4, 5),
    (3, 4),
    (2, 3),
    (1, 2),
    (0, 1),
  ];

  final Map<int, Ship> ships = {};
  final fogLayer = PositionComponent(priority: 5);
  final labelLayer = PositionComponent(priority: 4);
  final shipLayer = PositionComponent(priority: 3);

  late SelectControlComponent _selectControl;
  final _corners = Hex.zero
      .polygonCorners()
      .map((e) => e.toOffset())
      .toList(growable: false);
  late Picture _cachedMap;
  bool _isDirty = true;

  void markDirty() => _isDirty = true;

  set selectControl(SelectControlComponent s) {
    _selectControl.removeFromParent();
    _selectControl = s;
    add(_selectControl);
  }

  SelectControlComponent get selectControl => _selectControl;

  void blockSelect() {
    selectControl = SelectControlInputBlocked();
  }

  void deselect() {
    selectControl = SelectControlWaitForInput();
  }

  void start(GameSettings gameSettings) {
    for (final List<Cell> col in game.g.cells) {
      addAll(col);
    }

    for (final planet in game.g.planets) {
      labelLayer.add(
        TextComponent(
          text: planet.name,
          textRenderer: FlameTheme.text16pale,
          position: planet.hex.toPixel() + Vector2(0, -48),
          anchor: Anchor.center,
        ),
      );
    }
  }

  void addShip(Unit unit) {
    final cell = game.g.cells[unit.hex.x][unit.hex.y];
    cell.unit = unit;
    final ship = Ship(unit.playerNumber, unit.hex);
    ships[unit.uid] = ship;
    shipLayer.add(ship);
  }

  void reset() {
    for (final planet in game.g.planets) {
      planet.removeFromParent();
    }
    game.g.planets.clear();
  }

  @override
  FutureOr<void> onLoad() {
    _selectControl = SelectControlWaitForInput();
    addAll([_selectControl, fogLayer, labelLayer, shipLayer]);

    return super.onLoad();
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    return true;
  }

  @override
  void onTapUp(TapUpEvent event) {
    final hex = pixelToHex(event.localPosition);

    final cell = game.g.cells[hex.x][hex.y];
    selectControl.onCellClick(cell);

    super.onTapUp(event);
  }

  @override
  void render(Canvas canvas) {
    if (_isDirty) {
      _recache();
    }

    canvas.drawPicture(_cachedMap);
  }

  void _recache() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    for (final col in game.g.cells) {
      for (final cell in col) {
        canvas.renderAt(cell.position, (myCanvas) {
          for (final (i, j) in _cornerIndices) {
            canvas.drawLine(
              _corners[i],
              _corners[j],
              FlameTheme.hexBorderPaint,
            );
          }
        });
      }
    }

    _cachedMap = recorder.endRecording();
    _isDirty = false;
  }

  Hex pixelToHex(Vector2 pixel) {
    final cells = game.g.cells;
    final int x = ((pixel.x + horiz * 0.5) / horiz).floor().clamp(
      0,
      cells.length - 1,
    );
    final int y = ((pixel.y + vert * 0.5 - (x & 1) * vert * 0.5) / vert)
        .floor()
        .clamp(0, cells[0].length - 1);

    return Hex(x, y);
  }

  Hex neighbour(Hex hex, int direction) {
    final parity = hex.x & 1;
    final diff = oddqDirectionDiff[parity][direction];
    final mapX = (hex.x + diff[0]).clamp(0, game.g.cells.length - 1);
    final mapY = (hex.y + diff[1]).clamp(0, game.g.cells[0].length - 1);

    return Hex(mapX, mapY);
  }

  List<Cell> getNeighbours(Hex hex) {
    final Set<Hex> existing = {hex};
    final List<Cell> neighbours = [];
    for (int i = 0; i < 6; i++) {
      final neighbourHex = neighbour(hex, i);
      if (existing.contains(neighbourHex)) {
        continue;
      }
      existing.add(neighbourHex);
      neighbours.add(game.g.cells[neighbourHex.x][neighbourHex.y]);
    }
    return neighbours;
  }

  Map<Cell, AStarInfo> findAllPath(
    Cell originalNode,
    int playerNumber,
    int movementPoint,
  ) {
    final frontier = HeapPriorityQueue<_CellItem>((
      _CellItem itemA,
      _CellItem itemB,
    ) {
      return itemA.priority - itemB.priority;
    });
    frontier.add(_CellItem(originalNode, 0));

    final Map<Cell, Cell> cameFrom = {originalNode: originalNode};
    final Map<Cell, int> costSoFar = {originalNode: 0};

    while (frontier.isNotEmpty) {
      final current = frontier.removeFirst();
      final neighbours = getNeighbours(current.cell.hex);
      for (final neighbour in neighbours) {
        final newCost = costSoFar[current.cell]! + neighbour.tileType.cost;
        // Hostile ship or planet
        if (neighbour.hasEnemy(playerNumber)) {
          continue;
        }

        if (newCost > movementPoint) {
          continue;
        }
        if (!costSoFar.containsKey(neighbour) ||
            (newCost < costSoFar[neighbour]!)) {
          costSoFar[neighbour] = newCost;
          cameFrom[neighbour] = current.cell;
          frontier.add(_CellItem(neighbour, newCost));
        }
      }
    }

    final Map<Cell, AStarInfo> paths = {};
    for (final destination in cameFrom.keys) {
      final List<Cell> path = [];
      Cell current = destination;
      // Cell is occupied by other ship
      if (current.unit != null) {
        continue;
      }
      while (current != originalNode) {
        path.add(current);
        current = cameFrom[current]!;
      }

      paths[destination] = AStarInfo(path, costSoFar[destination]!);
    }

    return paths;
  }

  void moveShip(Unit unit, AStarInfo path) {
    final ship = ships[unit.uid]!;
    ship.prepMove(path);
  }
}
