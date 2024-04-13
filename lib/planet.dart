import 'dart:async';
import 'dart:ui' show Paint, PaintingStyle;
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

import 'player_state.dart';
import 'building.dart';
import 'scifi_game.dart';
import "hex.dart";
import "planet_type.dart";
import "theme.dart" show text12, emptyPaint;

class Planet extends PositionComponent
    with HasGameRef<ScifiGame>, ChangeNotifier {
  PlanetType type;

  /// 0 = small, 1 = medium, 2 = large
  int planetSize;
  int? playerNumber;
  int developmentLevel = 0;
  int food = 0;
  int citizen = 0;
  int trade = 0;
  int support = 0;
  double defense = 0;
  bool isUnderSiege = false;
  final List<Building> buildings = [];
  bool homePlanet = false;
  String displayName = "";

  final Hex hex;
  final Hex sector;
  final TextComponent populationLabel = TextComponent(
      text: "",
      position: Vector2(0, 36),
      anchor: Anchor.center,
      textRenderer: text12);
  final CircleComponent ownerCircle =
      CircleComponent(radius: 36, paint: emptyPaint, anchor: Anchor.center);
  late final SpriteComponent planetSprite;
  Planet(this.type, this.hex, this.sector, {this.planetSize = 1})
      : super(anchor: Anchor.center);

  @override
  FutureOr<void> onLoad() {
    final img = game.images.fromCache(type.image);
    final double xPos = switch (planetSize) {
      0 => 0,
      1 => 72,
      _ => 144,
    };
    final srcPos = Vector2(xPos, 0);
    final sprite = Sprite(img, srcPosition: srcPos, srcSize: Vector2.all(72));
    planetSprite = SpriteComponent(sprite: sprite, anchor: Anchor.center);

    addAll([planetSprite, ownerCircle, populationLabel]);

    updateRender();
  }

  void setHomePlanet(int playerNumber) {
    this.playerNumber = playerNumber;
    type = PlanetType.terran;
    planetSize = 1;
    homePlanet = true;
    citizen = 100;
    support = 100;
    buildings.addAll([
      Building.colonyHQ,
      Building.fusionReactor,
    ]);
    food = type.food;
    defense = defenseMax();
  }

  void colonize(int playerNumber, int population) {
    this.playerNumber = playerNumber;
    updateRender();
  }

  void capture(int playerNumber) {
    this.playerNumber = playerNumber;
    citizen ~/= 2;
    updateRender();
  }

  void updateRender() {
    final popLabel = citizen > 0 ? citizen.toString() : '';

    if (playerNumber == null) {
      ownerCircle.paint = emptyPaint;
      populationLabel.text = "";
    } else {
      populationLabel.text = "[$popLabel]$displayName";
      final pState = game.controller.getPlayerState(playerNumber!);
      final playerPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = pState.color;
      ownerCircle.paint = playerPaint;
    }
  }

  void phaseUpdate(int playerNumber) {
    if (this.playerNumber != playerNumber) {
      return;
    }
    _citizenUpdate();
    _citizenWork();

    supportUpdate();

    updateRender();
  }

  void _citizenUpdate() {
    for (int i = 0; i < 3; i++) {
      _citizenGrow();
      _citizenDecay();
    }
  }

  int growth() {
    int buildingGrowth = 0;
    for (final bd in buildings) {
      if (bd == Building.colonyHQ) {
        buildingGrowth += 5;
      }
    }
    return food + buildingGrowth;
  }

  void _citizenGrow() {
    citizen += growth();
  }

  void _citizenDecay() {
    citizen -= (citizen.toDouble() * 0.4 / 1.0).floor();
    citizen = citizen.clamp(0, 99999);
  }

  void _citizenWork() {
    defense += citizen;
    defense = defense.clamp(0, defenseMax());
  }

  int calcSupport() {
    double tradeEffectMultiplier = 1.0;
    if (type.climate == PlanetClimate.cold) {
      tradeEffectMultiplier -= 0.2;
    }
    double tradeSupportMultiplier = 1.0 + developmentLevel * 0.1;
    final tradeSupport =
        citizen * tradeSupportMultiplier - trade * tradeEffectMultiplier;
    double buildingSupport = 0;
    for (final bd in buildings) {
      if (bd == Building.policeStation) {
        buildingSupport += 100;
      }
    }

    return (tradeSupport + buildingSupport).floor();
  }

  void supportUpdate() {
    support += calcSupport();
    support = support.clamp(0, 100);
  }

  bool isFoodDeveloped() {
    return food == type.food;
  }

  void developFood(int playerNumber) {
    food += 10;
    food = food.clamp(0, type.food);
    notifyListeners();
  }

  int investNumber() {
    int ret = 5;
    if (playerNumber == null) {
      return ret;
    }
    PlayerState playerState = game.controller.getPlayerState(playerNumber!);
    if (playerState.sectorDataTable.containsKey(sector)) {
      final sectorData = playerState.sectorDataTable[sector]!;
      ret += sectorData.invest;
    }

    return ret;
  }

  void investTrade(int playerNumber) {
    trade += investNumber();
    notifyListeners();
  }

  bool canUpgrade() {
    return developmentLevel < 2;
  }

  void upgrade() {
    developmentLevel = (developmentLevel + 1).clamp(0, 2);
    updateRender();
    notifyListeners();
  }

  bool canBuild(Building bd) {
    if (bd.uniqueTag.isNotEmpty) {
      for (final b in buildings) {
        if (b.uniqueTag == bd.uniqueTag) {
          return false;
        }
      }
    }
    return buildings.length < maxBuilding();
  }

  void build(Building bd) {
    buildings.add(bd);
    updateRender();
    notifyListeners();
  }

  double defenseMax() {
    return 300 + developmentLevel * 100;
  }

  int maxBuilding() {
    return planetSize + 2;
  }

  int lifeQuality() {
    int qol = type.lifeQuality;

    return 90 + planetSize * 10 + qol + developmentLevel * 10;
  }

  double tax() {
    return citizen * (0.25 + developmentLevel * 0.05);
  }

  double tradeIncome() {
    return trade * (support / 100);
  }

  bool attackable(int playerNumber) {
    if (this.playerNumber == null) {
      return false;
    }
    return this.playerNumber != playerNumber;
  }

  bool neutral() {
    return playerNumber == null;
  }

  String planetSizeStr() {
    return switch (planetSize) {
      0 => "Small",
      1 => "Medium",
      _ => "Large",
    };
  }
}
