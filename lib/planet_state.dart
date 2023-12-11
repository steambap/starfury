import "planet_type.dart";
import "building.dart";

class PlanetState {
  PlanetType planetType;
  int? playerNumber;
  int population = 0;
  List<Building> buildings = [];

  PlanetState(this.planetType);
}