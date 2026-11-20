import '../models/partida.dart';

class BallThrowUsage {
  const BallThrowUsage({
    required this.frame,
    required this.throwIndex,
    required this.ballId,
    required this.pins,
    required this.fullRack,
    required this.strike,
    required this.spare,
  });
  final int frame, throwIndex, pins;
  final String? ballId;
  final bool fullRack, strike, spare;
}

/// Physical pins from recorded symbols; score bonuses are never attributed to a ball.
List<BallThrowUsage> recordedBallThrows(Partida game) {
  final result = <BallThrowUsage>[];
  for (var f = 0; f < game.frames.length && f < 10; f++) {
    var remaining = 10;
    var rackIsFresh = true;
    for (var t = 0; t < game.frames[f].length && t < (f == 9 ? 3 : 2); t++) {
      if (t > 0 && f < 9 && game.frames[f][0] == 'X') break;
      if (t == 2 && !(game.frames[f][0] == 'X' || game.frames[f][1] == '/'))
        break;
      final token = game.frames[f][t].trim().toUpperCase();
      if (token.isEmpty) break;
      final full = rackIsFresh;
      final int? pins = token == 'X'
          ? (full ? 10 : null)
          : token == '/'
          ? (!full ? remaining : null)
          : token == '-'
          ? 0
          : int.tryParse(token);
      if (pins == null || pins < 0 || pins > remaining) break;
      final strike = full && pins == 10;
      final spare = !full && pins == remaining;
      result.add(
        BallThrowUsage(
          frame: f,
          throwIndex: t,
          ballId: game.ballForThrow(f, t),
          pins: pins,
          fullRack: full,
          strike: strike,
          spare: spare,
        ),
      );
      remaining -= pins;
      if (f == 9 && remaining == 0) {
        remaining = 10;
        rackIsFresh = true;
      } else {
        rackIsFresh = false;
      }
    }
  }
  return result;
}

class BallUsageStats {
  BallUsageStats(Iterable<Partida> games, String? id) {
    for (final game in games) {
      final records = recordedBallThrows(
        game,
      ).where((r) => r.ballId == id).toList();
      throwsCount += records.length;
      framesCount += records.map((r) => r.frame).toSet().length;
      for (final r in records) {
        pins += r.pins;
        if (r.fullRack) {
          fullRackThrows++;
          if (r.strike) strikes++;
        } else {
          spareAttempts++;
          if (r.spare) spares++;
        }
      }
    }
  }
  int throwsCount = 0,
      framesCount = 0,
      pins = 0,
      fullRackThrows = 0,
      strikes = 0,
      spareAttempts = 0,
      spares = 0;
  double? get strikeRate =>
      fullRackThrows == 0 ? null : 100 * strikes / fullRackThrows;
  double? get spareRate =>
      spareAttempts == 0 ? null : 100 * spares / spareAttempts;
}
