import 'package:hive/hive.dart';

part 'friend.g.dart';

/// Representa un amigo en el sistema
@HiveType(typeId: 11)
class Friend extends HiveObject {
  @HiveField(0)
  String userId; // Firebase UID del amigo

  @HiveField(1)
  String nombre;

  @HiveField(2)
  String? email;

  @HiveField(3)
  String? photoUrl;

  @HiveField(4)
  DateTime fechaAmistad; // Cuando se aceptó la solicitud

  @HiveField(5)
  double? promedioGeneral; // Promedio de puntuación (cache)

  @HiveField(6)
  int? totalPartidas; // Total de partidas (cache)

  Friend({
    required this.userId,
    required this.nombre,
    this.email,
    this.photoUrl,
    required this.fechaAmistad,
    this.promedioGeneral,
    this.totalPartidas,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'nombre': nombre,
        'email': email,
        'photoUrl': photoUrl,
        'fechaAmistad': fechaAmistad.toIso8601String(),
        'promedioGeneral': promedioGeneral,
        'totalPartidas': totalPartidas,
      };

  factory Friend.fromJson(Map<String, dynamic> json) => Friend(
        userId: json['userId'],
        nombre: json['nombre'],
        email: json['email'],
        photoUrl: json['photoUrl'],
        fechaAmistad: DateTime.parse(json['fechaAmistad']),
        promedioGeneral: json['promedioGeneral']?.toDouble(),
        totalPartidas: json['totalPartidas'],
      );

  Friend copyWith({
    String? userId,
    String? nombre,
    String? email,
    String? photoUrl,
    DateTime? fechaAmistad,
    double? promedioGeneral,
    int? totalPartidas,
  }) {
    return Friend(
      userId: userId ?? this.userId,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      fechaAmistad: fechaAmistad ?? this.fechaAmistad,
      promedioGeneral: promedioGeneral ?? this.promedioGeneral,
      totalPartidas: totalPartidas ?? this.totalPartidas,
    );
  }
}
