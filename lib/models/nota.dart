import 'package:hive/hive.dart';

part 'nota.g.dart';

@HiveType(typeId: 2)
class Nota extends HiveObject {
  @HiveField(0)
  String titulo;

  @HiveField(1)
  String contenido;

  @HiveField(2)
  DateTime fechaCreacion;

  @HiveField(3)
  DateTime fechaModificacion;

  Nota({
    required this.titulo,
    required this.contenido,
    required this.fechaCreacion,
    required this.fechaModificacion,
  });

  Nota copyWith({
    String? titulo,
    String? contenido,
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
  }) {
    return Nota(
      titulo: titulo ?? this.titulo,
      contenido: contenido ?? this.contenido,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaModificacion: fechaModificacion ?? this.fechaModificacion,
    );
  }

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'contenido': contenido,
        'fechaCreacion': fechaCreacion.toIso8601String(),
        'fechaModificacion': fechaModificacion.toIso8601String(),
      };

  factory Nota.fromJson(Map<String, dynamic> json) => Nota(
        titulo: json['titulo'] as String,
        contenido: json['contenido'] as String,
        fechaCreacion: DateTime.parse(json['fechaCreacion'] as String),
        fechaModificacion: DateTime.parse(json['fechaModificacion'] as String),
      );
}
