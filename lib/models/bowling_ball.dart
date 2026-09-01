import 'dart:math';
import 'package:hive/hive.dart';

part 'bowling_ball.g.dart';

/// Predefined maintenance type keys for [BallMaintenance].
class BallMaintenanceType {
  static const String cleaning = 'cleaning';
  static const String resurfacing = 'resurfacing';
  static const String oilExtraction = 'oilExtraction';
  static const String other = 'other';

  static const List<String> values = [
    cleaning,
    resurfacing,
    oilExtraction,
    other,
  ];

  /// Human readable label (Spanish) for UI display.
  static String label(String type) {
    switch (type) {
      case cleaning:
        return 'Limpieza';
      case resurfacing:
        return 'Resurfacing';
      case oilExtraction:
        return 'Extracción de aceite';
      default:
        return 'Otro';
    }
  }
}

/// Represents a bowling ball owned by the user, part of their equipment
/// inventory ("Mis Bolas").
@HiveType(typeId: 19)
class BowlingBall extends HiveObject {
  /// Stable identifier for the ball.
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? brand;

  @HiveField(3)
  double weightLbs;

  @HiveField(4)
  String? coverstock;

  @HiveField(5)
  String? finish;

  @HiveField(6)
  DateTime? purchaseDate;

  /// Whether the ball is currently in active use. Soft-deleted (archived)
  /// balls are kept with `isActive = false` to preserve historical stats.
  @HiveField(7)
  bool isActive;

  @HiveField(8)
  String? notes;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime updatedAt;

  BowlingBall({
    String? id,
    required this.name,
    this.brand,
    required this.weightLbs,
    this.coverstock,
    this.finish,
    this.purchaseDate,
    this.isActive = true,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = (id == null || id.trim().isEmpty) ? generateStableId() : id.trim(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  BowlingBall copyWith({
    String? name,
    Object? brand = _sentinel,
    double? weightLbs,
    Object? coverstock = _sentinel,
    Object? finish = _sentinel,
    Object? purchaseDate = _sentinel,
    bool? isActive,
    Object? notes = _sentinel,
    DateTime? updatedAt,
  }) {
    return BowlingBall(
      id: id,
      name: name ?? this.name,
      brand: brand == _sentinel ? this.brand : brand as String?,
      weightLbs: weightLbs ?? this.weightLbs,
      coverstock: coverstock == _sentinel ? this.coverstock : coverstock as String?,
      finish: finish == _sentinel ? this.finish : finish as String?,
      purchaseDate:
          purchaseDate == _sentinel ? this.purchaseDate : purchaseDate as DateTime?,
      isActive: isActive ?? this.isActive,
      notes: notes == _sentinel ? this.notes : notes as String?,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'weightLbs': weightLbs,
        'coverstock': coverstock,
        'finish': finish,
        'purchaseDate': purchaseDate?.toIso8601String(),
        'isActive': isActive,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory BowlingBall.fromJson(Map<String, dynamic> json) => BowlingBall(
        id: json['id'] as String?,
        name: json['name'] as String? ?? '',
        brand: json['brand'] as String?,
        weightLbs: (json['weightLbs'] as num?)?.toDouble() ?? 0,
        coverstock: json['coverstock'] as String?,
        finish: json['finish'] as String?,
        purchaseDate: _parseDateTime(json['purchaseDate']),
        isActive: json['isActive'] as bool? ?? true,
        notes: json['notes'] as String?,
        createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
      );
}

/// Represents a maintenance record performed on a [BowlingBall].
@HiveType(typeId: 20)
class BallMaintenance extends HiveObject {
  @HiveField(0)
  String id;

  /// Foreign key referencing [BowlingBall.id].
  @HiveField(1)
  String ballId;

  /// Maintenance type key (see [BallMaintenanceType]).
  @HiveField(2)
  String type;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String? notes;

  BallMaintenance({
    String? id,
    required this.ballId,
    String? type,
    DateTime? date,
    this.notes,
  })  : id = (id == null || id.trim().isEmpty) ? generateStableId() : id.trim(),
        type = _normalizeType(type),
        date = date ?? DateTime.now();

  BallMaintenance copyWith({
    String? ballId,
    String? type,
    DateTime? date,
    Object? notes = _sentinel,
  }) {
    return BallMaintenance(
      id: id,
      ballId: ballId ?? this.ballId,
      type: type ?? this.type,
      date: date ?? this.date,
      notes: notes == _sentinel ? this.notes : notes as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ballId': ballId,
        'type': type,
        'date': date.toIso8601String(),
        'notes': notes,
      };

  factory BallMaintenance.fromJson(Map<String, dynamic> json) => BallMaintenance(
        id: json['id'] as String?,
        ballId: json['ballId'] as String? ?? '',
        type: json['type'] as String?,
        date: _parseDateTime(json['date']) ?? DateTime.now(),
        notes: json['notes'] as String?,
      );
}

/// Sentinel object used in `copyWith` to distinguish null from "not provided".
const Object _sentinel = Object();

String _normalizeType(String? type) {
  if (type != null && BallMaintenanceType.values.contains(type)) {
    return type;
  }
  return BallMaintenanceType.other;
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

final Random _idRandom = Random();
int _idCounter = 0;

/// Generates a stable, sufficiently unique identifier without pulling in an
/// external uuid dependency, matching the pattern already used by [Nota].
String generateStableId() {
  final now = DateTime.now().microsecondsSinceEpoch;
  _idCounter = (_idCounter + 1) & 0xFFFFF;
  final random = _idRandom.nextInt(1 << 32);
  return '${now}_${_idCounter}_$random';
}
