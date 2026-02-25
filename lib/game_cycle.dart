import 'package:flame/components.dart';

import 'scifi_game.dart';
import 'hud_state.dart';

class GameCycle extends Component with HasGameReference<ScifiGame> {
  int _eventProcessState = -1;

  @override
  void update(double dt) {
    if (_eventProcessState == 2) {
      _playerEndTurnProcess();
    }

    if (_eventProcessState > 5) {
      _eventProcessState = -1;
    } else if (_eventProcessState >= 0) {
      _eventProcessState++;
    }

    super.update(dt);
  }

  void startNewGame() {
    runProduction(game.g.moveOrderTurn);
  }

  /// For player end turn
  void endTurn() {
    game.watchMode = true;
    _eventProcessState = 0;
  }

  /// For player unit auto move and event result auto process
  void _playerEndTurnProcess() {
    endTurnCalc();
  }

  void endTurnCalc() {
    game.g.moveOrderTurn += 1;
    if (game.g.moveOrderTurn >= game.g.players.length) {
      game.g.moveOrderTurn = 0;
      game.g.turn += 1;
    }

    runProduction(game.g.moveOrderTurn);
    resetUnitMove();
    if (game.g.players[game.g.moveOrderTurn].isAI) {
      endTurnCalc();
    } else {
      game.watchMode = false;
      game.getIt<HudState>().updatePlayerInfo();
    }
  }

  double playerIncome(int playerNumber) {
    double income = 0;

    for (final planet in game.g.planets) {
      if (planet.playerIdx == playerNumber) {
        income += planet.isHome() ? 20 : 5;
      }
    }

    return income;
  }

  double humanPlayerIncome() {
    return playerIncome(game.g.humanPlayerIdx);
  }

  void runProduction(int playerNumber) {
    final player = game.g.players[playerNumber];

    player.resources += playerIncome(playerNumber);
  }

  void resetUnitMove() {
    final cells = game.g.cells;
    for (final cellCols in cells) {
      for (final cell in cellCols) {
          cell.unit?.resetMove();
      }
    }
  }
}
