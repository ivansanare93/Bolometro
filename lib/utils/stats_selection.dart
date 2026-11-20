import '../models/sesion.dart';
import '../models/partida.dart';
import 'app_constants.dart';
import 'stats_filter.dart';

/// Reading order only; never modifies stored sessions, game lists or IDs.
abstract final class StatsSelection {
  /// Normalize display spelling only. Never rewrite stored venue names or ball IDs.
  static String? venueKey(Sesion s) {
    final value = s.lugar.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    return value.isEmpty ? null : value;
  }

  static String? ballKey(Partida p) =>
      p.usedBallIds.length == 1 && !p.hasUnassignedThrows
      ? p.usedBallIds.single
      : null;
  static Iterable<String> ballKeys(Partida p) => p.usedBallIds;

  static String sessionKey(Sesion s) => s.key != null
      ? 'hive_${s.key}'
      : '${s.fecha.millisecondsSinceEpoch}|${Uri.encodeComponent(s.lugar)}|'
            '${Uri.encodeComponent(s.tipo)}|${Uri.encodeComponent(s.temporadaNormalizada)}';

  static List<Sesion> chronologicalSessions(List<Sesion> sessions) =>
      List<Sesion>.from(sessions)..sort((a, b) {
        final date = a.fecha.compareTo(b.fecha);
        return date != 0 ? date : sessionKey(a).compareTo(sessionKey(b));
      });

  /// Missing game dates inherit the session date. Ties preserve recorded game order.
  static List<(Sesion, Partida)> games(List<Sesion> sessions) {
    final entries = <(Sesion, Partida, int)>[];
    for (final s in chronologicalSessions(sessions)) {
      for (var i = 0; i < s.partidas.length; i++) {
        entries.add((s, s.partidas[i], i));
      }
    }
    entries.sort((a, b) {
      final date = (a.$2.fecha ?? a.$1.fecha).compareTo(
        b.$2.fecha ?? b.$1.fecha,
      );
      if (date != 0) return date;
      final session = a.$1.fecha.compareTo(b.$1.fecha);
      if (session != 0) return session;
      final key = sessionKey(a.$1).compareTo(sessionKey(b.$1));
      return key != 0 ? key : a.$3.compareTo(b.$3);
    });
    return entries.map((e) => (e.$1, e.$2)).toList();
  }

  static StatsFilter availableFilter(
    List<Sesion> sessions,
    StatsFilter filter,
  ) => filter.copyWith(
    clearTemporada:
        filter.temporada != null &&
        !sessions.any((s) => s.temporadaNormalizada == filter.temporada),
    clearBall:
        filter.ballId != null &&
        !sessions.any((s) => s.partidas.any((p) => p.usesBall(filter.ballId!))),
    clearVenue:
        filter.venue != null &&
        !sessions.any((s) => venueKey(s) == filter.venue),
    clearSessionKey:
        filter.sessionKey != null &&
        !sessions.any((s) => sessionKey(s) == filter.sessionKey),
  );

  static List<Sesion> apply(
    List<Sesion> sessions,
    StatsFilter filter, {
    DateTime? now,
  }) {
    final todayTime = now ?? DateTime.now();
    final today = DateTime(todayTime.year, todayTime.month, todayTime.day);
    DateTime? start;
    DateTime? end;
    switch (filter.datePreset) {
      case DateRangePreset.allTime:
        break;
      case DateRangePreset.last7Days:
        start = DateTime(today.year, today.month, today.day - 6);
        end = today;
        break;
      case DateRangePreset.last30Days:
        start = DateTime(today.year, today.month, today.day - 29);
        end = today;
        break;
      case DateRangePreset.last90Days:
        start = DateTime(today.year, today.month, today.day - 89);
        end = today;
        break;
      case DateRangePreset.thisMonth:
        start = DateTime(today.year, today.month);
        end = today;
        break;
      case DateRangePreset.thisYear:
        start = DateTime(today.year);
        end = today;
        break;
      case DateRangePreset.custom:
        start = filter.customRange?.start;
        end = filter.customRange?.end;
        break;
    }
    final from = start == null
        ? null
        : DateTime(start.year, start.month, start.day);
    final until = end == null
        ? null
        : DateTime(end.year, end.month, end.day + 1);
    var selected = chronologicalSessions(
      sessions
          .where(
            (s) =>
                (filter.tipo == AppConstants.tipoTodos ||
                    s.tipo == filter.tipo) &&
                (filter.temporada == null ||
                    s.temporadaNormalizada == filter.temporada) &&
                (filter.venue == null || venueKey(s) == filter.venue) &&
                (!filter.withoutVenue || venueKey(s) == null) &&
                (filter.sessionKey == null ||
                    sessionKey(s) == filter.sessionKey) &&
                (from == null || !s.fecha.isBefore(from)) &&
                (until == null || s.fecha.isBefore(until)),
          )
          .toList(),
    );
    if (filter.ballId != null || filter.withoutBall) {
      selected = selected
          .map(
            (s) => s.copyWith(
              partidas: s.partidas
                  .where(
                    (p) =>
                        (filter.ballId == null || p.usesBall(filter.ballId!)) &&
                        (!filter.withoutBall || p.hasUnassignedThrows),
                  )
                  .toList(),
            ),
          )
          .where((s) => s.partidas.isNotEmpty)
          .toList();
    }
    final limit = filter.lastN.limit;
    if (limit == null) return selected;
    final entries = games(selected);
    final kept = entries.length > limit
        ? entries.sublist(entries.length - limit)
        : entries;
    final grouped = <Sesion, List<Partida>>{};
    for (final (s, p) in kept) {
      grouped.putIfAbsent(s, () => []).add(p);
    }
    return chronologicalSessions(
      grouped.entries.map((e) => e.key.copyWith(partidas: e.value)).toList(),
    );
  }
}
