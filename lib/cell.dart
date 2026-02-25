import 'dart:async';
import 'dart:ui' show Paint;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import 'scifi_game.dart';
import 'hex.dart';
import 'planet.dart';
import 'unit.dart';
import "styles.dart";
import 'tile_type.dart';

class Cell extends PositionComponent with HasGameReference<ScifiGame> {
  final Hex hex;
  Planet? planet;
  late final PolygonComponent _highligher;
  late final PolygonComponent _fog;
  TileType tileType = TileType.empty;
  SpriteComponent? tileSprite;
  Unit? unit;

  Cell(this.hex) : super(anchor: Anchor.center) {
    position = hex.toPixel();
    _highligher = PolygonComponent(
      Hex.zero.polygonCorners(),
      anchor: Anchor.center,
      paint: FlameTheme.highlighterPaint,
      priority: 2,
    );
    _fog = PolygonComponent(
      Hex.zero.polygonCorners(Hex.size - 0.5),
      position: position,
      anchor: Anchor.center,
      paint: Paint.from(FlameTheme.fogPaint),
    );
  }

  @override
  FutureOr<void> onLoad() {
    final offset = Object.hash(hex.x, hex.y, 0) % 3;
    Sprite? sprite;
    if (tileType == TileType.gravityRift) {
      sprite = Sprite(
        game.images.fromCache("terrain.png"),
        srcPosition: Vector2(168 * offset.toDouble(), 504),
        srcSize: Vector2.all(168),
      );
    } else if (tileType == TileType.nebula) {
      sprite = Sprite(
        game.images.fromCache("terrain.png"),
        srcPosition: Vector2(168 * offset.toDouble(), 168),
        srcSize: Vector2.all(168),
      );
    } else if (tileType == TileType.asteroidField) {
      sprite = Sprite(
        game.images.fromCache("terrain.png"),
        srcPosition: Vector2(168 * offset.toDouble(), 336),
        srcSize: Vector2.all(168),
      );
    }

    if (sprite != null) {
      tileSprite = SpriteComponent(sprite: sprite, anchor: Anchor.center);
      add(tileSprite!);
    }
    if (planet != null) {
      add(planet!);
    }

    // showFog();
  }

  bool isValid() {
    return hex != Hex.invalid;
  }

  void showFog() {
    game.mapGrid.fogLayer.add(_fog);
  }

  void hideFog() {
    _fog.removeFromParent();
  }

  /// Hide fog with animation
  void reveal() {
    if (_fog.parent == null) {
      return;
    }

    _fog.add(OpacityEffect.fadeOut(EffectController(duration: 0.75)));
  }

  void unmark() {
    _highligher.removeFromParent();
  }

  FutureOr<void> markAsHighlight() {
    _highligher.paint = FlameTheme.highlighterPaint;

    return add(_highligher);
  }

  @override
  int get hashCode => hex.hashCode;

  @override
  bool operator ==(Object other) {
    return (other is Cell) && hex == other.hex;
  }

  @override
  String toString() {
    return "Cell$hex,${tileType.name}";
  }

  String toShortString() {
    final tileStr = switch (tileType) {
      TileType.empty => "",
      TileType.gravityRift => "G",
      TileType.nebula => "Nebula",
      TileType.asteroidField => "Asteroid Field",
    };
    return "$tileStr $hex";
  }

  Map<String, dynamic> toJson() {
    return {
      "hex": hex,
      "tileType": tileType.name,
      // sectors and ships are saved under map grid
    };
  }

  bool hasEnemyShip(int playerNumber) {
    return unit != null && unit!.playerNumber != playerNumber;
  }

  bool isBlocked(int playerNumber) {
    return planet?.hasEnemy(playerNumber) ?? false;
  }

  bool hasEnemy(int playerNumber) {
    return hasEnemyShip(playerNumber) || isBlocked(playerNumber);
  }
}
