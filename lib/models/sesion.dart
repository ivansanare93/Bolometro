import 'package:hive/hive.dart';
import '../utils/app_constants.dart';
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

  @HiveField(5)
  String? temporada;

  Sesion({
    required this.fecha,
    required this.lugar,
    required this.tipo,
    required this.partidas,
    this.notas,
    this.temporada,
  });

  Sesion copyWith({
    DateTime? fecha,
    String? lugar,
    String? tipo,
    List<Partida>? partidas,
    String? notas,
    String? temporada,
    bool clearTemporada = false,
  }) {
    return Sesion(
      fecha: fecha ?? this.fecha,
      lugar: lugar ?? this.lugar,
      tipo: tipo ?? this.tipo,
      partidas: partidas ?? this.partidas,
      notas: notas ?? this.notas,
      temporada: clearTemporada ? null : (temporada ?? this.temporada),
    );
  }

  String get temporadaNormalizada {
    final valor = temporada?.trim();
    if (valor == null || valor.isEmpty) {
      return AppConstants.temporadaSinTemporada;
    }
    return valor;
  }

  Map<String, dynamic> toJson() => {
        'fecha': fecha.toIso8601String(),
        'lugar': lugar,
        'tipo': tipo,
        'notas': notas,
        'temporada': temporada,
        'partidas': partidas.map((p) => p.toJson()).toList(),
      };

  factory Sesion.fromJson(Map<String, dynamic> json) => Sesion(
        fecha: DateTime.parse(json['fecha']),
        lugar: json['lugar'],
        tipo: json['tipo'],
        notas: json['notas'],
        temporada: json['temporada'] as String?,
        partidas: (json['partidas'] as List<dynamic>)
            .map((p) => Partida.fromJson(p))
            .toList(),
      );
}
