import 'package:hive/hive.dart';

part 'partida.g.dart'; // Importante para generar el adaptador

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

  @HiveField(5)
  final List<List<List<int>?>>? pinosPorTiro;

  Partida({
    required this.fecha,
    required this.lugar,
    required this.frames,
    this.notas,
    required this.total,
    this.pinosPorTiro,
  });

  // Actualiza también copyWith y toJson
  Partida copyWith({
    DateTime? fecha,
    String? lugar,
    List<List<String>>? frames,
    String? notas,
    int? total,
    List<List<List<int>?>>? pinosPorTiro, // Añadido
  }) {
    return Partida(
      fecha: fecha ?? this.fecha,
      lugar: lugar ?? this.lugar,
      frames: frames ?? this.frames,
      notas: notas ?? this.notas,
      total: total ?? this.total,
      pinosPorTiro: pinosPorTiro ?? this.pinosPorTiro, // Añadido
    );
  }

  Map<String, dynamic> toJson() => {
    'fecha': fecha.toIso8601String(),
    'lugar': lugar,
    'frames': frames,
    'notas': notas,
    'total': total,
    'pinosPorTiro': pinosPorTiro
        ?.map(
          (frame) => frame
              .map((tiro) => tiro?.toList()) // List<int>? -> List<int>?
              .toList(),
        )
        .toList(),
  };

  factory Partida.fromJson(Map<String, dynamic> json) => Partida(
    fecha: DateTime.parse(json['fecha']),
    lugar: json['lugar'],
    frames: List<List<String>>.from(
      json['frames'].map<List<String>>(
        (f) => List<String>.from(f.map((x) => x.toString())),
      ),
    ),
    notas: json['notas'],
    total: json['total'],
    pinosPorTiro: json['pinosPorTiro'] != null
        ? List<List<List<int>?>>.from(
            (json['pinosPorTiro'] as List).map(
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
