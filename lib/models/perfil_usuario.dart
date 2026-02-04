import 'package:hive/hive.dart';

part 'perfil_usuario.g.dart'; // ¡Recuerda generar el adapter!

@HiveType(typeId: 10) // Usa un typeId diferente y único para cada modelo Hive
class PerfilUsuario extends HiveObject {
  @HiveField(0)
  String nombre;

  @HiveField(1)
  String? email; // Opcional, útil para el futuro login

  @HiveField(2)
  String? avatarPath; // Ruta de la imagen local o URL futura

  @HiveField(3)
  String? club;

  @HiveField(4)
  String? manoDominante; // "Derecha", "Izquierda", etc.

  @HiveField(5)
  DateTime? fechaNacimiento;

  @HiveField(6)
  String? bio; // Pequeña descripción

  @HiveField(7)
  String? googlePhotoUrl; // URL de la foto de perfil de Google

  @HiveField(8)
  String? googleDisplayName; // Nombre de Google

  @HiveField(9)
  bool isFromGoogle; // Indica si el perfil fue creado desde Google

  @HiveField(10)
  String? friendCode; // Código único para agregar amigos

  PerfilUsuario({
    required this.nombre,
    this.email,
    this.avatarPath,
    this.club,
    this.manoDominante,
    this.fechaNacimiento,
    this.bio,
    this.googlePhotoUrl,
    this.googleDisplayName,
    this.isFromGoogle = false,
    this.friendCode,
  });

  /// Verifica si el perfil tiene una foto de Google disponible
  bool get hasGooglePhoto => googlePhotoUrl?.isNotEmpty ?? false;

  /// Crea una copia del perfil con los campos especificados actualizados
  PerfilUsuario copyWith({
    String? nombre,
    String? email,
    String? avatarPath,
    String? club,
    String? manoDominante,
    DateTime? fechaNacimiento,
    String? bio,
    String? googlePhotoUrl,
    String? googleDisplayName,
    bool? isFromGoogle,
    String? friendCode,
  }) {
    return PerfilUsuario(
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      avatarPath: avatarPath ?? this.avatarPath,
      club: club ?? this.club,
      manoDominante: manoDominante ?? this.manoDominante,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      bio: bio ?? this.bio,
      googlePhotoUrl: googlePhotoUrl ?? this.googlePhotoUrl,
      googleDisplayName: googleDisplayName ?? this.googleDisplayName,
      isFromGoogle: isFromGoogle ?? this.isFromGoogle,
      friendCode: friendCode ?? this.friendCode,
    );
  }
}
