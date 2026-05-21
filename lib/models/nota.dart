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

/// Structured note type keys for bowling learning logs.
class NotaTipo {
  static const String tecnica = 'tecnica';
  static const String pista = 'pista';
  static const String aceite = 'aceite';
  static const String equipamiento = 'equipamiento';
  static const String mental = 'mental';
  static const String review = 'review';

  static const List<String> values = [
    tecnica,
    pista,
    aceite,
    equipamiento,
    mental,
    review,
  ];
}

/// Validation lifecycle state for notes.
class NotaEstado {
  static const String pendiente = 'pendiente';
  static const String probado = 'probado';
  static const String validado = 'validado';
  static const String descartado = 'descartado';

  static const List<String> values = [
    pendiente,
    probado,
    validado,
    descartado,
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

  /// Structured type of note (technique, lane, oil, equipment, mental, review).
  @HiveField(12)
  String tipo;

  /// Validation state of the note (pending, tested, validated, discarded).
  @HiveField(13)
  String estado;

  /// Optional context metadata: bowling alley.
  @HiveField(14)
  String? bolera;

  /// Optional context metadata: oil pattern.
  @HiveField(15)
  String? patronAceite;

  /// Optional context metadata: ball/equipment used.
  @HiveField(16)
  String? equipamientoUsado;

  /// Optional context metadata: lane condition.
  @HiveField(17)
  String? condicionPista;

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
    String? tipo,
    String? estado,
    this.bolera,
    this.patronAceite,
    this.equipamientoUsado,
    this.condicionPista,
  })  : id = (id == null || id.trim().isEmpty) ? _generateStableId() : id.trim(),
        tipo = _normalizeTipo(tipo, categoria),
        estado = _normalizeEstado(estado),
        tags = _normalizeTags(tags);

  static List<String> normalizeTagsFromText(String rawTags) {
    return _normalizeTags(rawTags.split(RegExp(r'[,\n]')).toList());
  }

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
    String? tipo,
    String? estado,
    Object? bolera = _sentinel,
    Object? patronAceite = _sentinel,
    Object? equipamientoUsado = _sentinel,
    Object? condicionPista = _sentinel,
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
      tipo: tipo ?? this.tipo,
      estado: estado ?? this.estado,
      bolera: bolera == _sentinel ? this.bolera : bolera as String?,
      patronAceite: patronAceite == _sentinel
          ? this.patronAceite
          : patronAceite as String?,
      equipamientoUsado: equipamientoUsado == _sentinel
          ? this.equipamientoUsado
          : equipamientoUsado as String?,
      condicionPista: condicionPista == _sentinel
          ? this.condicionPista
          : condicionPista as String?,
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
        'tipo': tipo,
        'estado': estado,
        'bolera': bolera,
        'patronAceite': patronAceite,
        'equipamientoUsado': equipamientoUsado,
        'condicionPista': condicionPista,
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
        tipo: json['tipo'] as String?,
        estado: json['estado'] as String?,
        bolera: json['bolera'] as String?,
        patronAceite: json['patronAceite'] as String?,
        equipamientoUsado: json['equipamientoUsado'] as String?,
        condicionPista: json['condicionPista'] as String?,
      );
}

/// Sentinel object used in [Nota.copyWith] to distinguish null from "not provided".
const Object _sentinel = Object();

List<String> _normalizeTags(List<String>? tags) {
  if (tags == null) return <String>[];
  final normalized = tags
      .map((t) => t.toString().trim().toLowerCase())
      .where((t) => t.isNotEmpty)
      .toSet()
      .toList();
  normalized.sort();
  return normalized;
}

final Random _idRandom = Random();
int _idCounter = 0;

String _generateStableId() {
  final now = DateTime.now().microsecondsSinceEpoch;
  _idCounter = (_idCounter + 1) & 0xFFFFF;
  final random = _idRandom.nextInt(1 << 32);
  return '${now}_${_idCounter}_$random';
}

String _normalizeTipo(String? tipo, String? categoria) {
  final normalized = tipo?.trim().toLowerCase();
  if (normalized != null && NotaTipo.values.contains(normalized)) {
    return normalized;
  }
  return _defaultTipoFromCategoria(categoria);
}

String _defaultTipoFromCategoria(String? categoria) {
  switch (categoria) {
    case NotaCategoria.tecnica:
      return NotaTipo.tecnica;
    case NotaCategoria.aceite:
      return NotaTipo.aceite;
    case NotaCategoria.equipamiento:
      return NotaTipo.equipamiento;
    case NotaCategoria.mental:
      return NotaTipo.mental;
    case NotaCategoria.bolera:
      return NotaTipo.pista;
    default:
      return NotaTipo.review;
  }
}

String _normalizeEstado(String? estado) {
  final normalized = estado?.trim().toLowerCase();
  if (normalized != null && NotaEstado.values.contains(normalized)) {
    return normalized;
  }
  return NotaEstado.pendiente;
}
