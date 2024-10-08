import 'package:flutter/material.dart' show Color, Colors;
import "package:flutter/foundation.dart" show ChangeNotifier;

import "resource.dart";
import "ship_hull.dart";
import "empire.dart";
import "hex.dart";
import "sim_props.dart";
import "data/tech.dart";

class PlayerState with ChangeNotifier, SimObject {
  static const double foodMax = 50;

  final int playerNumber;
  Color color = Colors.black;
  late final Empire empire;
  int team = -1;
  bool isAlive = true;
  final bool isAI;
  // Resources
  int support = 0;
  int production = 0;
  int credit = 0;
  int science = 0;
  // Status
  int nextActionCost = 1;
  final List<ShipHull> hulls = [];
  final Set<Hex> vision = {};
  final Set<String> techs = {};

  PlayerState(this.playerNumber, this.isAI);

  void init() {
    hulls.addAll(empire.startingHulls);
    refreshStatus();
  }

  void addResource(Resources resource) {
    support += resource.support;
    production += resource.production;
    credit += resource.credit;
    science += resource.science;

    notifyListeners();
  }

  bool canTakeAction() {
    return support >= nextActionCost;
  }

  void takeAction(Resources res) {
    support -= nextActionCost;
    nextActionCost += 1;
    addResource(res);
  }

  void onNewTurn(Resources res) {
    nextActionCost = 1;
    addResource(res);
  }

  void refreshStatus() {
    notifyListeners();
  }

  void addTech(String techId) {
    assert(techMap.containsKey(techId), "Tech $techId not found");
    techs.add(techId);
    props.addAll(techMap[techId]!.effects);
    notifyListeners();
  }
}
