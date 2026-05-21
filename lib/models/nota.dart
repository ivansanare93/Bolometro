import 'dart:math';
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

  /// Stable identifier for the note.
  @HiveField(7)
  String id;

  /// Free-form tags to improve note discovery.
  @HiveField(8)
  List<String> tags;

  /// Whether this note is pinned.
  @HiveField(9)
  bool pinned;

  /// Whether this note is archived.
  @HiveField(10)
  bool archivada;

  /// Optional related session identifier.
  @HiveField(11)
  String? relatedSessionId;

  Nota({
    required this.titulo,
    required this.contenido,
    required this.fechaCreacion,
    required this.fechaModificacion,
    this.categoria,
    this.favorita = false,
    this.colorValue,
    String? id,
    List<String>? tags,
    this.pinned = false,
    this.archivada = false,
    this.relatedSessionId,
  })  : id = (id == null || id.trim().isEmpty) ? _generateStableId() : id.trim(),
        tags = _normalizeTags(tags);

  Nota copyWith({
    String? titulo,
    String? contenido,
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
    Object? categoria = _sentinel,
    bool? favorita,
    Object? colorValue = _sentinel,
    String? id,
    List<String>? tags,
    bool? pinned,
    bool? archivada,
    Object? relatedSessionId = _sentinel,
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
      id: id ?? this.id,
      tags: tags ?? this.tags,
      pinned: pinned ?? this.pinned,
      archivada: archivada ?? this.archivada,
      relatedSessionId: relatedSessionId == _sentinel
          ? this.relatedSessionId
          : relatedSessionId as String?,
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
        'id': id,
        'tags': tags,
        'pinned': pinned,
        'archivada': archivada,
        'relatedSessionId': relatedSessionId,
      };

  factory Nota.fromJson(Map<String, dynamic> json) => Nota(
        titulo: json['titulo'] as String,
        contenido: json['contenido'] as String,
        fechaCreacion: DateTime.parse(json['fechaCreacion'] as String),
        fechaModificacion: DateTime.parse(json['fechaModificacion'] as String),
        categoria: json['categoria'] as String?,
        favorita: json['favorita'] as bool? ?? false,
        colorValue: json['colorValue'] as int?,
        id: (json['id'] as String?)?.trim(),
        tags: (json['tags'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
        pinned: json['pinned'] as bool? ?? false,
        archivada: json['archivada'] as bool? ?? false,
        relatedSessionId: json['relatedSessionId'] as String?,
      );
}

/// Sentinel object used in [Nota.copyWith] to distinguish null from "not provided".
const Object _sentinel = Object();

List<String> _normalizeTags(List<String>? tags) {
  if (tags == null) return <String>[];
  final normalized = tags
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toSet()
      .toList();
  normalized.sort();
  return normalized;
}

String _generateStableId() {
  final now = DateTime.now().microsecondsSinceEpoch;
  final random = Random().nextInt(1 << 32);
  return '${now}_$random';
}
