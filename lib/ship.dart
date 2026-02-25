import 'dart:async';
import 'dart:ui' show Paint, PaintingStyle;

import 'package:flame/components.dart';

import 'scifi_game.dart';
import 'hex.dart';
import 'map_grid.dart';

class Ship extends PositionComponent with HasGameReference<ScifiGame> {
  static const double attackRange = 24;

  final int playerIdx;
  final RectangleComponent _rectangle = RectangleComponent(
    size: Vector2.all(50),
    anchor: Anchor.center,
  );
  late SpriteComponent _iconLevel;
  late SpriteComponent _unitSize;

  Hex hex;
  AStarInfo _astar = AStarInfo.empty();
  int _pathC = 0;
  int _unitMoving = 0;

  Ship(this.playerIdx, this.hex) : super(anchor: Anchor.center);

  @override
  FutureOr<void> onLoad() {
    final unitImage = game.images.fromCache("units.png");
    _iconLevel = SpriteComponent(
      sprite: Sprite(
        unitImage,
        srcPosition: Vector2.zero(),
        srcSize: Vector2.all(64),
      ),
      anchor: Anchor.center,
    );
    _unitSize = SpriteComponent(
      sprite: Sprite(
        unitImage,
        srcPosition: Vector2(960, 0),
        srcSize: Vector2.all(64),
      ),
      anchor: Anchor.center,
    );

    _rectangle.paintLayers = [
      Paint()..color = game.g.players[playerIdx].color,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    ];

    addAll([_rectangle, _iconLevel, _unitSize]);

    position = hex.toPixel();

    return super.onLoad();
  }

  void prepMove(AStarInfo astarInfo) {
    _astar = astarInfo;
    _unitMoving = 1;
    _pathC = astarInfo.path.length - 1;
  }

  void _moveUnit() {
    game.watchMode = true;
    if (_pathC >= 0) {
      final cell = _astar.path[_pathC];
      position = cell.position;
      _pathC -= 1;
    } else {
      _endMove();
      game.watchMode = false;
    }
  }

  void _endMove() {
    final newCell = _astar.path.first;
    final prevCell = game.g.cells[hex.x][hex.y];

    newCell.unit = prevCell.unit;
    newCell.unit!.useMove(_astar.cost);
    prevCell.unit = null;

    hex = newCell.hex;

    _unitMoving = 0;
  }

  @override
  void update(double dt) {
    if (_unitMoving > 0) {
      _moveUnit();
    }

    super.update(dt);
  }
}
