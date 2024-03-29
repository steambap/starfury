import 'dart:async';
import 'dart:math';
import 'dart:ui' show Paint, PaintingStyle;
import 'package:flame/components.dart';

import 'facility.dart';
import 'scifi_game.dart';
import "hex.dart";
import "planet_type.dart";
import "theme.dart" show text12, emptyPaint;

class Planet extends PositionComponent with HasGameRef<ScifiGame> {
  PlanetType type;
  ColonyType _colonyType = ColonyType.none;

  /// 0 = small, 1 = medium, 2 = large
  int planetSize;
  int colonyTypeEffect = 0;
  int? playerNumber;
  int population = 0;
  double currentGrowth = 0;
  double energy = 0;
  double metal = 0;
  double defense = 0;
  bool isUnderSiege = false;
  final List<Facility> facilities = [];
  bool homePlanet = false;
  String displayName = "";

  final Hex hex;
  final TextComponent populationLabel = TextComponent(
      text: "",
      position: Vector2(0, 36),
      anchor: Anchor.center,
      textRenderer: text12);
  final CircleComponent ownerCircle =
      CircleComponent(radius: 36, paint: emptyPaint, anchor: Anchor.center);
  late final SpriteComponent planetSprite;
  Planet(this.type, this.hex, {this.planetSize = 1})
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

  ColonyType get colonyType => _colonyType;
  set colonyType(ColonyType colonyType) {
    _colonyType = colonyType;
    colonyTypeEffect = 0;
  }

  void setHomePlanet(int playerNumber) {
    this.playerNumber = playerNumber;
    type = PlanetType.terran;
    planetSize = 1;
    homePlanet = true;
    population = 5;
    facilities.addAll([
      Facility(FacilityType.medicalLab),
      Facility(FacilityType.fusionReactor),
      Facility(FacilityType.metalExtractor)
    ]);
    energy = energyMax() / 2;
    metal = metalMax() / 2;
    defense = defenseMax();
  }

  void colonize(int playerNumber, int population) {
    this.playerNumber = playerNumber;
    this.population = population;
    updateRender();
    game.playerInfo.updateRender();
  }

  void capture(int playerNumber) {
    this.playerNumber = playerNumber;
    population ~/= 2;
    updateRender();
    game.playerInfo.updateRender();
  }

  void updateRender() {
    final popLabel = population > 0 ? population.toString() : '';

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

  int maxPop() {
    return type.maxPopulation + planetSize;
  }

  int support() {
    int sum = 50 - type.support - population;
    if (playerNumber != null) {
      for (var s in game.mapGrid.planets) {
        if (s.playerNumber == playerNumber) {
          sum -= 6;
        }
      }
    }

    return max(sum, 0);
  }

  double growth() {
    int sum = type.growth;
    for (final f in facilities) {
      if (f.type == FacilityType.medicalLab) {
        sum += 15;
      }
      if (f.type == FacilityType.climateControlDevice) {
        sum += 5;
      }
    }

    return sum * (1.0 + (support() / 100));
  }

  void phaseUpdate(int playerNumber) {
    if (this.playerNumber != playerNumber) {
      return;
    }
    _popUpdate();
    _popWork();
    colonyTypeEffect += 1;
    colonyTypeEffect = colonyTypeEffect.clamp(0, 10);

    updateRender();
  }

  void _popUpdate() {
    if (population >= maxPop()) {
      return;
    }
    currentGrowth += growth();
    if (currentGrowth >= 100) {
      population++;
      currentGrowth -= 100;
    }
  }

  void _popWork() {
    if (energy >= energyMax() && metal >= metalMax()) {
      return;
    }
    final double mod = 1.0 + (support() / 100);

    if (energy >= energyMax()) {
      metal += population * 6 * mod;
    } else if (metal >= metalMax()) {
      energy += population * 6 * mod;
    } else {
      energy += population * 3 * mod;
      metal += population * 3 * mod;
    }

    energy = energy.clamp(0, energyMax());
    metal = metal.clamp(0, metalMax());
  }

  double energyMax() {
    double sum = type.energy * 100;
    for (final f in facilities) {
      if (f.type == FacilityType.fusionReactor) {
        sum += 100;
      }
    }

    return sum;
  }

  double metalMax() {
    double sum = type.metal * 100;
    for (final f in facilities) {
      if (f.type == FacilityType.metalExtractor) {
        sum += 100;
      }
    }

    return sum;
  }

  double defenseMax() {
    return 999;
  }

  double energyIncome() {
    double mod = 1.0;
    if (colonyType == ColonyType.powerGrid) {
      mod += colonyTypeEffect.toDouble() / 100;
    }
    return energy * mod;
  }

  double metalIncome() {
    double mod = 1.0;
    if (colonyType == ColonyType.miningBase) {
      mod += colonyTypeEffect.toDouble() / 100;
    }
    return metal * mod;
  }

  int maxFacilities() {
    return switch (planetSize) {
      0 => 7,
      1 => 10,
      _ => 12,
    };
  }

  void production(int playerNumber) {
    produceEnergy(playerNumber);
    produceMetal(playerNumber);
  }

  void produceEnergy(int playerNumber) {
    final playerState = game.controller.getPlayerState(playerNumber);
    final energy = energyIncome();
    playerState.energy += energy;
  }

  void produceMetal(int playerNumber) {
    final playerState = game.controller.getPlayerState(playerNumber);
    final metal = metalIncome();
    playerState.metal += metal;
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

  String colonyTypeEffectStr() {
    return switch (colonyType) {
      ColonyType.none => "None",
      ColonyType.militaryInstallation => "Military TODO",
      ColonyType.miningBase => "Metal + $colonyTypeEffect%",
      ColonyType.powerGrid => "Energy + $colonyTypeEffect%",
      ColonyType.researchStation => "Research TODO",
    };
  }
}
