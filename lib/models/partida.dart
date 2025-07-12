import 'package:hive/hive.dart';

part 'partida.g.dart';

@HiveType(typeId: 0)
class Partida extends HiveObject {
  @HiveField(0)
  final DateTime fecha;

  @HiveField(1)
  final String lugar;

  @HiveField(2)
  final List<List<String>> frames;

  @HiveField(3)
  final String? notas;

  @HiveField(4)
  final int total;

  /// [pinesPorTiro] = [ [ [pines tiro 1], [pines tiro 2], [pines tiro 3] ], ...] (10 frames)
  /// Cada [pines tiro x] es `List<int>` de bolos tirados (1-10), o null si no se usó.
  @HiveField(5)
  final List<List<List<int>?>>? pinesPorTiro;

  Partida({
    required this.fecha,
    required this.lugar,
    required this.frames,
    this.notas,
    required this.total,
    this.pinesPorTiro,
  });

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
    'fecha': fecha.toIso8601String(),
    'lugar': lugar,
    'frames': frames,
    'notas': notas,
    'total': total,
    'pinesPorTiro': pinesPorTiro
        ?.map((frame) => frame.map((tiro) => tiro?.toList()).toList())
        .toList(),
  };

  factory Partida.fromJson(Map<String, dynamic> json) => Partida(
    fecha: DateTime.parse(json['fecha']),
    lugar: json['lugar'],
    frames: List<List<String>>.from(
      (json['frames'] as List).map(
        (f) => List<String>.from(f.map((x) => x.toString())),
      ),
    ),
    notas: json['notas'],
    total: json['total'],
    pinesPorTiro: json['pinesPorTiro'] != null
        ? List<List<List<int>?>>.from(
            (json['pinesPorTiro'] as List).map(
              (frame) => List<List<int>?>.from(
                (frame as List).map(
                  (tiro) => tiro == null ? null : List<int>.from(tiro as List),
                ),
              ),
            ),
          )
        : null,
  );
}
