import 'cell.dart';
import "planet.dart";
import "player.dart";

class State {
  final List<List<Cell>> cells = [];
  final List<Planet> planets = [];
  final List<Player> players = [];
  int humanPlayerIdx = 0;
  int turn = 0;
  int moveOrderTurn = 0;
  int _uid = 0;

  int get uid => _uid;

  int nextUID() {
    return _uid++;
  }

  Map<String, dynamic> toJson() {
    return {
      'cells': cells,
      'planets': planets,
      'players': players,
      'humanPlayerIdx': humanPlayerIdx,
      'turn': turn,
      'moveOrderTurn': moveOrderTurn,
      'uid': _uid,
    };
  }
}
