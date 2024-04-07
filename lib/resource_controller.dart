import "scifi_game.dart";
import "player_state.dart";
import "planet.dart";
import "building.dart";
import "resource.dart";

class ResourceController {
  final ScifiGame game;

  ResourceController(this.game);

  void runProduction(int playerNumber) {
    final playerState = game.controller.getPlayerState(playerNumber);
    final income = playerIncome(playerNumber);

    playerState.production += income.production;
    playerState.production = playerState.production.clamp(0, 200);
    playerState.credit += income.credit;
    playerState.influence = income.influence;
  }

  Resources playerIncome(int playerNumber) {
    final playerState = game.controller.getPlayerState(playerNumber);
    Resources income = Resources();

    for (final planet in game.mapGrid.planets) {
      if (planet.playerNumber == playerNumber) {
        income += calcPlanetIncome(playerState, planet);
      }
    }

    return income;
  }

  Resources humanPlayerIncome() {
    final idx = game.controller.getHumanPlayerNumber();

    return playerIncome(idx);
  }

  Resources calcPlanetIncome(PlayerState playerState, Planet planet) {
    Resources income = Resources();

    for (final bd in planet.buildings) {
      if (bd == Building.galacticHQ) {
        income += Resources(production: 10, credit: 20, influence: 5);
      } else if (bd == Building.factory) {
        income += Resources(production: 10);
      } else if (bd == Building.fusionReactor) {
        income += Resources(credit: 80);
      } else if (bd == Building.mediaNetwork) {
        income += Resources(influence: 5);
      }
    }

    income.credit += planet.tax() + planet.tradeIncome();
    income.production += planet.type.production;

    return income;
  }

  double getMaintaince(int playerNumber) {
    return 0;
  }

  bool canDevelopFood(int playerNumber, Planet planet) {
    final playerState = game.controller.getPlayerState(playerNumber);

    return playerState.production >= 8 && !planet.isFoodDeveloped();
  }

  bool developFood(int playerNumber, Planet planet) {
    final playerState = game.controller.getPlayerState(playerNumber);

    if (!canDevelopFood(playerNumber, planet)) {
      return false;
    }

    playerState.production -= 8;
    planet.developFood(playerNumber);

    return true;
  }

  bool canInvestTrade(int playerNumber, Planet planet) {
    final playerState = game.controller.getPlayerState(playerNumber);

    return playerState.production >= 8;
  }

  bool investTrade(int playerNumber, Planet planet) {
    final playerState = game.controller.getPlayerState(playerNumber);

    if (!canInvestTrade(playerNumber, planet)) {
      return false;
    }

    playerState.production -= 8;
    planet.investTrade(playerNumber);

    return true;
  }

  bool canUpgradePlanet(int playerNumber, Planet planet) {
    final playerState = game.controller.getPlayerState(playerNumber);

    return playerState.production >= 20 && planet.canUpgrade();
  }

  bool upgradePlanet(int playerNumber, Planet planet) {
    final playerState = game.controller.getPlayerState(playerNumber);

    if (!canUpgradePlanet(playerNumber, planet)) {
      return false;
    }

    playerState.production -= 20;
    planet.upgrade();

    return true;
  }
}
