import 'dart:math';
// import 'package:flame/components.dart';

// import 'scifi_game.dart';
import 'hex.dart';

class Unit {
  final int playerNumber;
  final int kind;
  final int uid;

  Hex hex;
  int moveLeft = 0;
  int health;
  int supplies = 0;
  int maxHealth = 0;
  int techLevel = 1;
  int experience = 0;
  int buildQueueTime = 0;
  bool isMoved = true;

  Unit({
    required this.uid,
    required this.playerNumber,
    required this.kind,
    required this.hex,
    this.health = 0,
  });

  String _name = "";
  String get name {
    if (_name.isEmpty) {
      return "Ship";
    }

    return _name;
  }

  set name(String value) {
    _name = value;
  }

  bool isAtMaxHealth() => health == maxHealth;

  bool isLowHealth() => health * 3 <= maxHealth;

  double healthFraction() => health * 1.0 / maxHealth;

  void moveLeft0() {
    moveLeft = 0;
    isMoved = true;
  }

  void useMove(int moveUsed) {
    moveLeft = max(moveLeft - moveUsed, 0);
    isMoved = true;
  }

  void resetMove() {
    moveLeft = 40;
    isMoved = false;
  }
}
