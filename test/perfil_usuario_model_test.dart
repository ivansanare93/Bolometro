import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/models/perfil_usuario.dart';

/// Tests for PerfilUsuario model
void main() {
  group('PerfilUsuario Model', () {
    test('PerfilUsuario should be created with required fields', () {
      // Act
      final perfil = PerfilUsuario(
        nombre: 'Juan Pérez',
      );

      // Assert
      expect(perfil.nombre, equals('Juan Pérez'));
      expect(perfil.email, isNull);
      expect(perfil.avatarPath, isNull);
      expect(perfil.club, isNull);
      expect(perfil.manoDominante, isNull);
      expect(perfil.fechaNacimiento, isNull);
      expect(perfil.bio, isNull);
      expect(perfil.googlePhotoUrl, isNull);
      expect(perfil.googleDisplayName, isNull);
      expect(perfil.isFromGoogle, isFalse);
      expect(perfil.friendCode, isNull);
    });

    test('PerfilUsuario should be created with all fields', () {
      // Arrange
      final fechaNacimiento = DateTime(1990, 5, 15);

      // Act
      final perfil = PerfilUsuario(
        nombre: 'Juan Pérez',
        email: 'juan@example.com',
        avatarPath: '/path/to/avatar.jpg',
        club: 'Club Deportivo',
        manoDominante: 'Derecha',
        fechaNacimiento: fechaNacimiento,
        bio: 'Jugador aficionado de bolos',
        googlePhotoUrl: 'https://example.com/photo.jpg',
        googleDisplayName: 'Juan P.',
        isFromGoogle: true,
        friendCode: 'ABC12345',
      );

      // Assert
      expect(perfil.nombre, equals('Juan Pérez'));
      expect(perfil.email, equals('juan@example.com'));
      expect(perfil.avatarPath, equals('/path/to/avatar.jpg'));
      expect(perfil.club, equals('Club Deportivo'));
      expect(perfil.manoDominante, equals('Derecha'));
      expect(perfil.fechaNacimiento, equals(fechaNacimiento));
      expect(perfil.bio, equals('Jugador aficionado de bolos'));
      expect(perfil.googlePhotoUrl, equals('https://example.com/photo.jpg'));
      expect(perfil.googleDisplayName, equals('Juan P.'));
      expect(perfil.isFromGoogle, isTrue);
      expect(perfil.friendCode, equals('ABC12345'));
    });

    test('PerfilUsuario with Google profile should have correct flags', () {
      // Act
      final perfil = PerfilUsuario(
        nombre: 'Google User',
        email: 'user@gmail.com',
        googlePhotoUrl: 'https://google.com/photo.jpg',
        googleDisplayName: 'Google User',
        isFromGoogle: true,
      );

      // Assert
      expect(perfil.isFromGoogle, isTrue);
      expect(perfil.googlePhotoUrl, isNotNull);
      expect(perfil.googleDisplayName, isNotNull);
      expect(perfil.email, equals('user@gmail.com'));
    });

    test('PerfilUsuario should handle left-handed player', () {
      // Act
      final perfil = PerfilUsuario(
        nombre: 'Left Handed Player',
        manoDominante: 'Izquierda',
      );

      // Assert
      expect(perfil.manoDominante, equals('Izquierda'));
    });

    test('PerfilUsuario should handle right-handed player', () {
      // Act
      final perfil = PerfilUsuario(
        nombre: 'Right Handed Player',
        manoDominante: 'Derecha',
      );

      // Assert
      expect(perfil.manoDominante, equals('Derecha'));
    });

    test('PerfilUsuario should handle birthdate correctly', () {
      // Arrange
      final birthDate = DateTime(1985, 12, 25);

      // Act
      final perfil = PerfilUsuario(
        nombre: 'Birthday Player',
        fechaNacimiento: birthDate,
      );

      // Assert
      expect(perfil.fechaNacimiento, equals(birthDate));
      expect(perfil.fechaNacimiento!.year, equals(1985));
      expect(perfil.fechaNacimiento!.month, equals(12));
      expect(perfil.fechaNacimiento!.day, equals(25));
    });

    test('PerfilUsuario can be updated with new values', () {
      // Arrange
      final perfil = PerfilUsuario(
        nombre: 'Original Name',
      );

      // Act
      perfil.nombre = 'Updated Name';
      perfil.email = 'new@example.com';
      perfil.club = 'New Club';

      // Assert
      expect(perfil.nombre, equals('Updated Name'));
      expect(perfil.email, equals('new@example.com'));
      expect(perfil.club, equals('New Club'));
    });

    test('PerfilUsuario should handle friend code correctly', () {
      // Act
      final perfil = PerfilUsuario(
        nombre: 'User with Code',
        friendCode: 'XYZ78901',
      );

      // Assert
      expect(perfil.friendCode, equals('XYZ78901'));
      expect(perfil.friendCode, isNotNull);
    });

    test('PerfilUsuario can be updated with friend code', () {
      // Arrange
      final perfil = PerfilUsuario(
        nombre: 'User without Code',
      );

      // Act
      perfil.friendCode = 'NEW12345';

      // Assert
      expect(perfil.friendCode, equals('NEW12345'));
    });
  });
}