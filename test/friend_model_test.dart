import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/models/friend.dart';

void main() {
  group('Friend Model Tests', () {
    test('Friend model should be created with required fields', () {
      final friend = Friend(
        userId: 'test_user_123',
        nombre: 'Juan Pérez',
        fechaAmistad: DateTime(2024, 1, 15),
      );

      expect(friend.userId, 'test_user_123');
      expect(friend.nombre, 'Juan Pérez');
      expect(friend.fechaAmistad, DateTime(2024, 1, 15));
      expect(friend.email, null);
      expect(friend.photoUrl, null);
    });

    test('Friend model should handle all fields correctly', () {
      final fecha = DateTime(2024, 1, 15);
      final friend = Friend(
        userId: 'test_user_123',
        nombre: 'Juan Pérez',
        email: 'juan@example.com',
        photoUrl: 'https://example.com/photo.jpg',
        fechaAmistad: fecha,
        promedioGeneral: 185.5,
        totalPartidas: 42,
      );

      expect(friend.userId, 'test_user_123');
      expect(friend.nombre, 'Juan Pérez');
      expect(friend.email, 'juan@example.com');
      expect(friend.photoUrl, 'https://example.com/photo.jpg');
      expect(friend.fechaAmistad, fecha);
      expect(friend.promedioGeneral, 185.5);
      expect(friend.totalPartidas, 42);
    });

    test('Friend toJson should serialize correctly', () {
      final fecha = DateTime(2024, 1, 15);
      final friend = Friend(
        userId: 'test_user_123',
        nombre: 'Juan Pérez',
        email: 'juan@example.com',
        photoUrl: 'https://example.com/photo.jpg',
        fechaAmistad: fecha,
        promedioGeneral: 185.5,
        totalPartidas: 42,
      );

      final json = friend.toJson();

      expect(json['userId'], 'test_user_123');
      expect(json['nombre'], 'Juan Pérez');
      expect(json['email'], 'juan@example.com');
      expect(json['photoUrl'], 'https://example.com/photo.jpg');
      expect(json['fechaAmistad'], fecha.toIso8601String());
      expect(json['promedioGeneral'], 185.5);
      expect(json['totalPartidas'], 42);
    });

    test('Friend fromJson should deserialize correctly', () {
      final fecha = DateTime(2024, 1, 15);
      final json = {
        'userId': 'test_user_123',
        'nombre': 'Juan Pérez',
        'email': 'juan@example.com',
        'photoUrl': 'https://example.com/photo.jpg',
        'fechaAmistad': fecha.toIso8601String(),
        'promedioGeneral': 185.5,
        'totalPartidas': 42,
      };

      final friend = Friend.fromJson(json);

      expect(friend.userId, 'test_user_123');
      expect(friend.nombre, 'Juan Pérez');
      expect(friend.email, 'juan@example.com');
      expect(friend.photoUrl, 'https://example.com/photo.jpg');
      expect(friend.fechaAmistad, fecha);
      expect(friend.promedioGeneral, 185.5);
      expect(friend.totalPartidas, 42);
    });

    test('Friend copyWith should create a new instance with updated values', () {
      final fecha = DateTime(2024, 1, 15);
      final friend = Friend(
        userId: 'test_user_123',
        nombre: 'Juan Pérez',
        fechaAmistad: fecha,
      );

      final updatedFriend = friend.copyWith(
        promedioGeneral: 190.0,
        totalPartidas: 50,
      );

      expect(updatedFriend.userId, 'test_user_123');
      expect(updatedFriend.nombre, 'Juan Pérez');
      expect(updatedFriend.fechaAmistad, fecha);
      expect(updatedFriend.promedioGeneral, 190.0);
      expect(updatedFriend.totalPartidas, 50);
    });

    test('Friend serialization and deserialization should be reversible', () {
      final fecha = DateTime(2024, 1, 15);
      final originalFriend = Friend(
        userId: 'test_user_123',
        nombre: 'Juan Pérez',
        email: 'juan@example.com',
        photoUrl: 'https://example.com/photo.jpg',
        fechaAmistad: fecha,
        promedioGeneral: 185.5,
        totalPartidas: 42,
      );

      final json = originalFriend.toJson();
      final deserializedFriend = Friend.fromJson(json);

      expect(deserializedFriend.userId, originalFriend.userId);
      expect(deserializedFriend.nombre, originalFriend.nombre);
      expect(deserializedFriend.email, originalFriend.email);
      expect(deserializedFriend.photoUrl, originalFriend.photoUrl);
      expect(deserializedFriend.fechaAmistad, originalFriend.fechaAmistad);
      expect(deserializedFriend.promedioGeneral, originalFriend.promedioGeneral);
      expect(deserializedFriend.totalPartidas, originalFriend.totalPartidas);
    });
  });
}
