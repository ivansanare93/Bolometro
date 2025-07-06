import 'package:hive/hive.dart';
import 'partida.dart';

part 'sesion.g.dart';

@HiveType(typeId: 1)
class Sesion extends HiveObject {
  @HiveField(0)
  DateTime fecha;

  @HiveField(1)
  String lugar;

  @HiveField(2)
  String tipo;

  @HiveField(3)
  List<Partida> partidas;

  @HiveField(4)
  String? notas;

  Sesion({
    required this.fecha,
    required this.lugar,
    required this.tipo,
    required this.partidas,
    this.notas,
  });

  Sesion copyWith({
    DateTime? fecha,
    String? lugar,
    String? tipo,
    List<Partida>? partidas,
    String? notas,
  }) {
    return Sesion(
      fecha: fecha ?? this.fecha,
      lugar: lugar ?? this.lugar,
      tipo: tipo ?? this.tipo,
      partidas: partidas ?? this.partidas,
      notas: notas ?? this.notas,
    );
  }

  Map<String, dynamic> toJson() => {
        'fecha': fecha.toIso8601String(),
        'lugar': lugar,
        'tipo': tipo,
        'notas': notas,
        'partidas': partidas.map((p) => p.toJson()).toList(),
      };

  factory Sesion.fromJson(Map<String, dynamic> json) => Sesion(
        fecha: DateTime.parse(json['fecha']),
        lugar: json['lugar'],
        tipo: json['tipo'],
        notas: json['notas'],
        partidas: (json['partidas'] as List<dynamic>)
            .map((p) => Partida.fromJson(p))
            .toList(),
      );
}
