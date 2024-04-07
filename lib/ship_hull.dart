import 'package:flame/components.dart';

class ShipHull {
  final String name;
  final int hullSize;
  final int life;
  final int armor;
  final Block speedRange;
  final int cost;

  ShipHull({
    required this.name,
    required this.hullSize,
    required this.life,
    required this.armor,
    required this.speedRange,
    required this.cost,
  });
}