import 'dart:convert';
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
enum LastNGames { all, last10, last25, last50 }

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
    this.temporada,
    this.sessionKey,
    this.ballId,
    this.withoutBall = false,
    this.venue,
    this.withoutVenue = false,
    this.datePreset = DateRangePreset.allTime,
    this.customRange,
    this.lastN = LastNGames.all,
  }) : assert(ballId == null || !withoutBall),
       assert(venue == null || !withoutVenue);

  final String tipo;
  final String? temporada;
  final String? sessionKey;
  final String? ballId;
  final bool withoutBall;
  final String? venue;
  final bool withoutVenue;
  final DateRangePreset datePreset;
  final DateTimeRange? customRange;
  final LastNGames lastN;

  /// A string key that uniquely identifies this filter combination.
  /// Used as the cache key inside [EstadisticasCache].
  String get cacheKey {
    return jsonEncode([
      tipo,
      temporada,
      sessionKey,
      datePreset.name,
      if (datePreset == DateRangePreset.custom)
        customRange?.start.toIso8601String(),
      if (datePreset == DateRangePreset.custom)
        customRange?.end.toIso8601String(),
      lastN.name,
      ballId,
      withoutBall,
      venue,
      withoutVenue,
    ]);
  }

  /// Telemetry describes controls only, never personal IDs, venues or season names.
  String get analyticsKey => jsonEncode([
    datePreset.name,
    lastN.name,
    temporada != null,
    sessionKey != null,
    ballId != null,
    withoutBall,
    venue != null,
    withoutVenue,
  ]);

  StatsFilter copyWith({
    String? tipo,
    String? temporada,
    String? sessionKey,
    DateRangePreset? datePreset,
    DateTimeRange? customRange,
    LastNGames? lastN,
    String? ballId,
    bool? withoutBall,
    String? venue,
    bool? withoutVenue,
    bool clearBall = false,
    bool clearVenue = false,
    bool clearTemporada = false,
    bool clearSessionKey = false,
    bool clearCustomRange = false,
  }) {
    return StatsFilter(
      tipo: tipo ?? this.tipo,
      ballId: clearBall || withoutBall == true ? null : (ballId ?? this.ballId),
      withoutBall: clearBall || ballId != null
          ? false
          : (withoutBall ?? this.withoutBall),
      venue: clearVenue || withoutVenue == true ? null : (venue ?? this.venue),
      withoutVenue: clearVenue || venue != null
          ? false
          : (withoutVenue ?? this.withoutVenue),
      temporada: clearTemporada ? null : (temporada ?? this.temporada),
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
        other.temporada == temporada &&
        other.sessionKey == sessionKey &&
        other.ballId == ballId &&
        other.withoutBall == withoutBall &&
        other.venue == venue &&
        other.withoutVenue == withoutVenue &&
        other.datePreset == datePreset &&
        other.customRange == customRange &&
        other.lastN == lastN;
  }

  @override
  int get hashCode => Object.hash(
    tipo,
    temporada,
    sessionKey,
    datePreset,
    customRange,
    lastN,
    ballId,
    withoutBall,
    venue,
    withoutVenue,
  );
}
