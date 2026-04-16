import 'package:hive/hive.dart';

part 'nota.g.dart';

/// Predefined category keys for bowling notes.
class NotaCategoria {
  static const String general = 'general';
  static const String aceite = 'aceite';
  static const String tecnica = 'tecnica';
  static const String equipamiento = 'equipamiento';
  static const String mental = 'mental';
  static const String bolera = 'bolera';

  static const List<String> values = [
    general,
    aceite,
    tecnica,
    equipamiento,
    mental,
    bolera,
  ];
}

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

  /// Category key (see [NotaCategoria]).
  @HiveField(4)
  String? categoria;

  /// Whether this note is marked as a favourite.
  @HiveField(5)
  bool favorita;

  /// ARGB colour value for the note accent. null = use theme primary colour.
  @HiveField(6)
  int? colorValue;

  Nota({
    required this.titulo,
    required this.contenido,
    required this.fechaCreacion,
    required this.fechaModificacion,
    this.categoria,
    this.favorita = false,
    this.colorValue,
  });

  Nota copyWith({
    String? titulo,
    String? contenido,
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
    Object? categoria = _sentinel,
    bool? favorita,
    Object? colorValue = _sentinel,
  }) {
    return Nota(
      titulo: titulo ?? this.titulo,
      contenido: contenido ?? this.contenido,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaModificacion: fechaModificacion ?? this.fechaModificacion,
      categoria: categoria == _sentinel ? this.categoria : categoria as String?,
      favorita: favorita ?? this.favorita,
      colorValue:
          colorValue == _sentinel ? this.colorValue : colorValue as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'contenido': contenido,
        'fechaCreacion': fechaCreacion.toIso8601String(),
        'fechaModificacion': fechaModificacion.toIso8601String(),
        'categoria': categoria,
        'favorita': favorita,
        'colorValue': colorValue,
      };

  factory Nota.fromJson(Map<String, dynamic> json) => Nota(
        titulo: json['titulo'] as String,
        contenido: json['contenido'] as String,
        fechaCreacion: DateTime.parse(json['fechaCreacion'] as String),
        fechaModificacion: DateTime.parse(json['fechaModificacion'] as String),
        categoria: json['categoria'] as String?,
        favorita: json['favorita'] as bool? ?? false,
        colorValue: json['colorValue'] as int?,
      );
}

/// Sentinel object used in [Nota.copyWith] to distinguish null from "not provided".
const Object _sentinel = Object();
