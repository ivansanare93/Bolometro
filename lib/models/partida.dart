import 'package:hive/hive.dart';

part 'partida.g.dart'; // Importante para generar el adaptador

@HiveType(typeId: 0)
class Partida extends HiveObject {
  @HiveField(0)
  final DateTime fecha;

  @HiveField(1)
  final String lugar;

  @HiveField(2)
  final String tipo; // 'Entrenamiento' o 'Competición'

  @HiveField(3)
  final List<List<String>> frames; // Cada frame: [tiro1, tiro2, (opcional tiroExtra)]

  @HiveField(4)
  final String? notas;

  @HiveField(5)
  final int total;

  Partida({
    required this.fecha,
    required this.lugar,
    required this.tipo,
    required this.frames,
    this.notas,
    required this.total,
  });

  // Método para duplicar una partida con cambios opcionales
  Partida copyWith({
    DateTime? fecha,
    String? lugar,
    String? tipo,
    List<List<String>>? frames,
    String? notas,
    int? total,
  }) {
    return Partida(
      fecha: fecha ?? this.fecha,
      lugar: lugar ?? this.lugar,
      tipo: tipo ?? this.tipo,
      frames: frames ?? this.frames,
      notas: notas ?? this.notas,
      total: total ?? this.total,
    );
  }

  // Getter útil
  double get promedioPorTirada {
    final totalTiradas = frames.fold<int>(
      0,
      (sum, frame) => sum + frame.length,
    );
    return totalTiradas == 0 ? 0 : total / totalTiradas;
  }

  // Para exportar (opcional)
  Map<String, dynamic> toJson() => {
    'fecha': fecha.toIso8601String(),
    'lugar': lugar,
    'tipo': tipo,
    'frames': frames,
    'notas': notas,
    'total': total,
  };

  // Para importar (opcional)
  factory Partida.fromJson(Map<String, dynamic> json) => Partida(
    fecha: DateTime.parse(json['fecha']),
    lugar: json['lugar'],
    tipo: json['tipo'],
    frames: List<List<String>>.from(
      json['frames'].map<List<String>>(
        (f) => List<String>.from(f.map((x) => x.toString())),
      ),
    ),
    notas: json['notas'],
    total: json['total'],
  );
}
