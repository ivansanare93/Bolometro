import '../models/partida.dart';
import 'app_constants.dart';

/// Sample sizes only: never infer pin identities from numeric scores.
class StatisticsPinSample {
  const StatisticsPinSample({
    required this.gamesWithPins,
    required this.firstThrows,
  });
  final int gamesWithPins;
  final int firstThrows;
  factory StatisticsPinSample.fromGames(List<Partida> games) {
    var withPins = 0;
    var first = 0;
    for (final game in games) {
      if (game.pinesPorTiro.any((f) => f.any((p) => p != null))) withPins++;
      for (final frame in game.pinesPorTiro.take(AppConstants.totalFrames)) {
        if (frame.isNotEmpty && frame[0] != null) first++;
      }
    }
    return StatisticsPinSample(gamesWithPins: withPins, firstThrows: first);
  }
}
