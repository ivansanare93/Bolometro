import 'package:hive/hive.dart';

part 'partida.g.dart';

@HiveType(typeId: 0)
class Partida extends HiveObject {
  @HiveField(0)
  final DateTime? fecha;

  @HiveField(1)
  final String? lugar;

  @HiveField(2)
  final List<List<String>> frames;

  @HiveField(3)
  final String? notas;

  @HiveField(4)
  final int total;

  /// [pinesPorTiro] = [ [ [pines tiro 1], [pines tiro 2], [pines tiro 3] ], ...] (10 frames)
  /// Cada [pines tiro x] es `List<int>` (pines caídos: 1-10), o null si no se usó.
  @HiveField(5)
  final List<List<List<int>?>> pinesPorTiro;

  /// Identificador opcional de la bola de bolos ([BowlingBall.id]) usada en
  /// esta partida. `null` significa "sin especificar".
  @HiveField(6)
  final String? ballId;

  /// Sparse zero-based "frame:throw" overrides. An explicit null means unknown;
  /// an absent key inherits ballId. Added without changing Hive fields 0..6.
  @HiveField(7)
  final Map<String, String?> ballIdsByThrow;

  static String throwKey(int frame, int throwIndex) {
    if (frame < 0 ||
        frame > 9 ||
        throwIndex < 0 ||
        throwIndex > (frame == 9 ? 2 : 1)) {
      throw RangeError('Invalid bowling throw');
    }
    return '$frame:$throwIndex';
  }

  static Map<String, String?> parseBallAssignments(Object? raw) {
    if (raw == null) return {};
    if (raw is! Map) throw const FormatException('Invalid ball assignments');
    final result = <String, String?>{};
    for (final entry in raw.entries) {
      final key = entry.key;
      if (key is! String || !RegExp(r'^[0-9]:[0-2]$').hasMatch(key)) {
        throw const FormatException('Invalid ball assignment position');
      }
      final pieces = key.split(':').map(int.parse).toList();
      if (pieces[0] != 9 && pieces[1] > 1)
        throw const FormatException('Invalid bonus throw');
      if (entry.value != null && entry.value is! String)
        throw const FormatException('Invalid ball ID');
      result[key] = entry.value as String?;
    }
    return result;
  }

  String? ballForThrow(int frame, int throwIndex) {
    final key = throwKey(frame, throwIndex);
    final value = ballIdsByThrow.containsKey(key)
        ? ballIdsByThrow[key]
        : ballId;
    return value == null || value.trim().isEmpty ? null : value;
  }

  Set<String> get referencedBallIds => {
    if (ballId != null && ballId!.trim().isNotEmpty) ballId!,
    ...ballIdsByThrow.values.whereType<String>().where(
      (id) => id.trim().isNotEmpty,
    ),
  };

  /// Only throws actually recorded in the score sheet, excluding unused slots.
  Iterable<(int, int)> get recordedThrowPositions sync* {
    for (var f = 0; f < frames.length && f < 10; f++) {
      final tokens = frames[f];
      if (tokens.isEmpty || tokens[0].trim().isEmpty) continue;
      yield (f, 0);
      if (f < 9 && tokens[0] == 'X') continue;
      if (tokens.length > 1 && tokens[1].trim().isNotEmpty) yield (f, 1);
      if (f == 9 &&
          (tokens[0] == 'X' || (tokens.length > 1 && tokens[1] == '/')) &&
          tokens.length > 2 &&
          tokens[2].trim().isNotEmpty)
        yield (f, 2);
    }
  }

  Set<String> get usedBallIds {
    final positions = recordedThrowPositions.toList();
    if (positions.isEmpty && ballIdsByThrow.isEmpty)
      return {if (ballId != null && ballId!.trim().isNotEmpty) ballId!};
    return {
      for (final (f, t) in positions)
        if (ballForThrow(f, t) != null) ballForThrow(f, t)!,
    };
  }

  bool get hasUnassignedThrows {
    final positions = recordedThrowPositions.toList();
    if (positions.isEmpty) return usedBallIds.isEmpty;
    return positions.any((p) => ballForThrow(p.$1, p.$2) == null);
  }

  bool usesBall(String id) => usedBallIds.contains(id);
  bool exclusivelyUsesBall(String? id) => id == null
      ? usedBallIds.isEmpty
      : usedBallIds.length == 1 &&
            usedBallIds.contains(id) &&
            !hasUnassignedThrows;

  Partida({
    this.fecha,
    this.lugar,
    required this.frames,
    this.notas,
    required this.total,
    List<List<List<int>?>>? pinesPorTiro,
    this.ballId,
    Map<String, String?>? ballIdsByThrow,
  }) : ballIdsByThrow = Map.unmodifiable(parseBallAssignments(ballIdsByThrow)),
       pinesPorTiro =
           pinesPorTiro ?? List.generate(10, (_) => List.filled(3, null));

  Partida copyWith({
    DateTime? fecha,
    String? lugar,
    List<List<String>>? frames,
    String? notas,
    int? total,
    List<List<List<int>?>>? pinesPorTiro,
    Object? ballId = _sentinel,
    Map<String, String?>? ballIdsByThrow,
  }) {
    return Partida(
      fecha: fecha ?? this.fecha,
      lugar: lugar ?? this.lugar,
      frames: frames ?? this.frames,
      notas: notas ?? this.notas,
      total: total ?? this.total,
      pinesPorTiro: pinesPorTiro ?? this.pinesPorTiro,
      ballId: ballId == _sentinel ? this.ballId : ballId as String?,
      ballIdsByThrow: ballIdsByThrow ?? this.ballIdsByThrow,
    );
  }

  Map<String, dynamic> toJson() => {
    'fecha': fecha?.toIso8601String(),
    'lugar': lugar,
    // Flatten frames from List<List<String>> to List<String> to avoid nested arrays
    'frames': frames.map((frame) => frame.join(',')).toList(),
    'notas': notas,
    'total': total,
    // Flatten pinesPorTiro from List<List<List<int>?>> to List<String> to avoid nested arrays
    // Each frame's data is serialized as a string where tiros are separated by ';'
    // and pins within a tiro are separated by ','
    'pinesPorTiro': pinesPorTiro.map((frame) {
      return frame
          .map((tiro) {
            if (tiro == null) return 'null';
            return tiro.join(',');
          })
          .join(';');
    }).toList(),
    'ballId': ballId,
    if (ballIdsByThrow.isNotEmpty) 'ballIdsByThrow': ballIdsByThrow,
  };

  factory Partida.fromJson(Map<String, dynamic> json) {
    // Parse frames - handle both old format (List<List<String>>) and new format (List<String>)
    List<List<String>> parsedFrames;
    if (json['frames'] is List && (json['frames'] as List).isNotEmpty) {
      final firstElement = (json['frames'] as List).first;
      if (firstElement is List) {
        // Old format: List<List<String>>
        parsedFrames = List<List<String>>.from(
          (json['frames'] as List).map(
            (f) => List<String>.from(f.map((x) => x.toString())),
          ),
        );
      } else {
        // New format: List<String> where each string contains comma-separated values
        parsedFrames = (json['frames'] as List)
            .map((frameStr) => frameStr.toString().split(','))
            .where((frame) => frame.isNotEmpty && frame.first.isNotEmpty)
            .map((frame) => List<String>.from(frame))
            .toList();
        // Ensure we have 10 frames
        while (parsedFrames.length < 10) {
          parsedFrames.add([]);
        }
      }
    } else {
      parsedFrames = List.generate(10, (_) => []);
    }

    // Parse pinesPorTiro - handle both old format and new format
    List<List<List<int>?>> parsedPinesPorTiro;
    if (json['pinesPorTiro'] != null) {
      final pinesData = json['pinesPorTiro'] as List;
      if (pinesData.isNotEmpty) {
        final firstElement = pinesData.first;
        if (firstElement is List) {
          // Old format: List<List<List<int>?>>
          parsedPinesPorTiro = List<List<List<int>?>>.from(
            pinesData.map(
              (frame) => List<List<int>?>.from(
                (frame as List).map(
                  (tiro) => tiro == null ? null : List<int>.from(tiro as List),
                ),
              ),
            ),
          );
        } else {
          // New format: List<String> where each string contains ';' separated tiros
          // and each tiro contains ',' separated pins
          parsedPinesPorTiro = pinesData.map((frameStr) {
            final tiros = frameStr.toString().split(';');
            return tiros.map((tiroStr) {
              if (tiroStr == 'null' || tiroStr.isEmpty) return null;
              return tiroStr.split(',').map((pin) => int.parse(pin)).toList();
            }).toList();
          }).toList();
          // Ensure each frame has 3 tiros
          parsedPinesPorTiro = parsedPinesPorTiro.map((frame) {
            while (frame.length < 3) {
              frame.add(null);
            }
            return frame.take(3).toList();
          }).toList();
          // Ensure we have 10 frames
          while (parsedPinesPorTiro.length < 10) {
            parsedPinesPorTiro.add(List.filled(3, null));
          }
        }
      } else {
        parsedPinesPorTiro = List.generate(10, (_) => List.filled(3, null));
      }
    } else {
      parsedPinesPorTiro = List.generate(10, (_) => List.filled(3, null));
    }

    return Partida(
      fecha: json['fecha'] != null ? DateTime.parse(json['fecha']) : null,
      lugar: json['lugar'],
      frames: parsedFrames,
      notas: json['notas'],
      total: json['total'],
      pinesPorTiro: parsedPinesPorTiro,
      ballId: json['ballId'] as String?,
      ballIdsByThrow: parseBallAssignments(json['ballIdsByThrow']),
    );
  }
}

/// Sentinel object used in [Partida.copyWith] to distinguish null from "not provided".
const Object _sentinel = Object();
