import 'package:flutter/material.dart';

/// Presets for date-range filtering on the statistics screen.
enum DateRangePreset {
  allTime,
  last7Days,
  last30Days,
  last90Days,
  thisMonth,
  thisYear,
  custom,
}

/// "Last N games" limiter applied after the type + date filters.
enum LastNGames {
  all,
  last10,
  last25,
  last50,
}

extension LastNGamesValue on LastNGames {
  /// Returns the numeric limit, or null when the preset is [LastNGames.all].
  int? get limit {
    switch (this) {
      case LastNGames.all:
        return null;
      case LastNGames.last10:
        return 10;
      case LastNGames.last25:
        return 25;
      case LastNGames.last50:
        return 50;
    }
  }
}

/// Immutable snapshot of all active statistics filters.
///
/// Used to derive a cache key and to drive the filtering pipeline in
/// [_EstadisticasPantallaCompletaState].
@immutable
class StatsFilter {
  const StatsFilter({
    this.tipo = 'Todos',
    this.sessionKey,
    this.datePreset = DateRangePreset.allTime,
    this.customRange,
    this.lastN = LastNGames.all,
  });

  final String tipo;
  final String? sessionKey;
  final DateRangePreset datePreset;
  final DateTimeRange? customRange;
  final LastNGames lastN;

  /// A string key that uniquely identifies this filter combination.
  /// Used as the cache key inside [EstadisticasCache].
  String get cacheKey {
    final rangePart = datePreset == DateRangePreset.custom && customRange != null
        ? 'custom_${customRange!.start.millisecondsSinceEpoch}_'
            '${customRange!.end.millisecondsSinceEpoch}'
        : datePreset.name;
    final lastNPart = lastN.limit?.toString() ?? 'all';
    final sessionPart = sessionKey ?? 'all_sessions';
    return '${tipo}_${sessionPart}_${rangePart}_$lastNPart';
  }

  StatsFilter copyWith({
    String? tipo,
    String? sessionKey,
    DateRangePreset? datePreset,
    DateTimeRange? customRange,
    LastNGames? lastN,
    bool clearSessionKey = false,
    bool clearCustomRange = false,
  }) {
    return StatsFilter(
      tipo: tipo ?? this.tipo,
      sessionKey: clearSessionKey ? null : (sessionKey ?? this.sessionKey),
      datePreset: datePreset ?? this.datePreset,
      customRange: clearCustomRange ? null : (customRange ?? this.customRange),
      lastN: lastN ?? this.lastN,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StatsFilter &&
        other.tipo == tipo &&
        other.sessionKey == sessionKey &&
        other.datePreset == datePreset &&
        other.customRange == customRange &&
        other.lastN == lastN;
  }

  @override
  int get hashCode =>
      Object.hash(tipo, sessionKey, datePreset, customRange, lastN);
}
