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

  PerfilUsuario({
    required this.nombre,
    this.email,
    this.avatarPath,
    this.club,
    this.manoDominante,
    this.fechaNacimiento,
    this.bio,
  });
}
