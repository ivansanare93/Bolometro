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

  Partida({
    this.fecha,
    this.lugar,
    required this.frames,
    this.notas,
    required this.total,
    List<List<List<int>?>>? pinesPorTiro,
  }) : pinesPorTiro =
           pinesPorTiro ?? List.generate(10, (_) => List.filled(3, null));

  Partida copyWith({
    DateTime? fecha,
    String? lugar,
    List<List<String>>? frames,
    String? notas,
    int? total,
    List<List<List<int>?>>? pinesPorTiro,
  }) {
    return Partida(
      fecha: fecha ?? this.fecha,
      lugar: lugar ?? this.lugar,
      frames: frames ?? this.frames,
      notas: notas ?? this.notas,
      total: total ?? this.total,
      pinesPorTiro: pinesPorTiro ?? this.pinesPorTiro,
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
      return frame.map((tiro) {
        if (tiro == null) return 'null';
        return tiro.join(',');
      }).join(';');
    }).toList(),
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
    );
  }
}
