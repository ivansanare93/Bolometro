import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/models/friend_request.dart';

void main() {
  group('FriendRequest Model Tests', () {
    test('FriendRequest model should be created with required fields', () {
      final createdAt = DateTime(2024, 1, 15);
      final request = FriendRequest(
        requestId: 'req_123',
        fromUserId: 'user_123',
        fromUserName: 'Juan Pérez',
        toUserId: 'user_456',
        createdAt: createdAt,
      );

      expect(request.requestId, 'req_123');
      expect(request.fromUserId, 'user_123');
      expect(request.fromUserName, 'Juan Pérez');
      expect(request.toUserId, 'user_456');
      expect(request.createdAt, createdAt);
      expect(request.status, 'pending');
      expect(request.respondedAt, null);
    });

    test('FriendRequest model should handle all fields correctly', () {
      final createdAt = DateTime(2024, 1, 15);
      final respondedAt = DateTime(2024, 1, 16);
      final request = FriendRequest(
        requestId: 'req_123',
        fromUserId: 'user_123',
        fromUserName: 'Juan Pérez',
        fromUserEmail: 'juan@example.com',
        fromUserPhotoUrl: 'https://example.com/photo.jpg',
        toUserId: 'user_456',
        createdAt: createdAt,
        status: 'accepted',
        respondedAt: respondedAt,
      );

      expect(request.requestId, 'req_123');
      expect(request.fromUserId, 'user_123');
      expect(request.fromUserName, 'Juan Pérez');
      expect(request.fromUserEmail, 'juan@example.com');
      expect(request.fromUserPhotoUrl, 'https://example.com/photo.jpg');
      expect(request.toUserId, 'user_456');
      expect(request.createdAt, createdAt);
      expect(request.status, 'accepted');
      expect(request.respondedAt, respondedAt);
    });

    test('FriendRequest status getters should work correctly', () {
      final createdAt = DateTime(2024, 1, 15);

      final pendingRequest = FriendRequest(
        requestId: 'req_1',
        fromUserId: 'user_1',
        fromUserName: 'User 1',
        toUserId: 'user_2',
        createdAt: createdAt,
        status: 'pending',
      );

      expect(pendingRequest.isPending, true);
      expect(pendingRequest.isAccepted, false);
      expect(pendingRequest.isRejected, false);

      final acceptedRequest = FriendRequest(
        requestId: 'req_2',
        fromUserId: 'user_1',
        fromUserName: 'User 1',
        toUserId: 'user_2',
        createdAt: createdAt,
        status: 'accepted',
      );

      expect(acceptedRequest.isPending, false);
      expect(acceptedRequest.isAccepted, true);
      expect(acceptedRequest.isRejected, false);

      final rejectedRequest = FriendRequest(
        requestId: 'req_3',
        fromUserId: 'user_1',
        fromUserName: 'User 1',
        toUserId: 'user_2',
        createdAt: createdAt,
        status: 'rejected',
      );

      expect(rejectedRequest.isPending, false);
      expect(rejectedRequest.isAccepted, false);
      expect(rejectedRequest.isRejected, true);
    });

    test('FriendRequest toJson should serialize correctly', () {
      final createdAt = DateTime(2024, 1, 15);
      final respondedAt = DateTime(2024, 1, 16);
      final request = FriendRequest(
        requestId: 'req_123',
        fromUserId: 'user_123',
        fromUserName: 'Juan Pérez',
        fromUserEmail: 'juan@example.com',
        fromUserPhotoUrl: 'https://example.com/photo.jpg',
        toUserId: 'user_456',
        createdAt: createdAt,
        status: 'accepted',
        respondedAt: respondedAt,
      );

      final json = request.toJson();

      expect(json['requestId'], 'req_123');
      expect(json['fromUserId'], 'user_123');
      expect(json['fromUserName'], 'Juan Pérez');
      expect(json['fromUserEmail'], 'juan@example.com');
      expect(json['fromUserPhotoUrl'], 'https://example.com/photo.jpg');
      expect(json['toUserId'], 'user_456');
      expect(json['createdAt'], createdAt.toIso8601String());
      expect(json['status'], 'accepted');
      expect(json['respondedAt'], respondedAt.toIso8601String());
    });

    test('FriendRequest fromJson should deserialize correctly', () {
      final createdAt = DateTime(2024, 1, 15);
      final respondedAt = DateTime(2024, 1, 16);
      final json = {
        'requestId': 'req_123',
        'fromUserId': 'user_123',
        'fromUserName': 'Juan Pérez',
        'fromUserEmail': 'juan@example.com',
        'fromUserPhotoUrl': 'https://example.com/photo.jpg',
        'toUserId': 'user_456',
        'createdAt': createdAt.toIso8601String(),
        'status': 'accepted',
        'respondedAt': respondedAt.toIso8601String(),
      };

      final request = FriendRequest.fromJson(json);

      expect(request.requestId, 'req_123');
      expect(request.fromUserId, 'user_123');
      expect(request.fromUserName, 'Juan Pérez');
      expect(request.fromUserEmail, 'juan@example.com');
      expect(request.fromUserPhotoUrl, 'https://example.com/photo.jpg');
      expect(request.toUserId, 'user_456');
      expect(request.createdAt, createdAt);
      expect(request.status, 'accepted');
      expect(request.respondedAt, respondedAt);
    });

    test('FriendRequest copyWith should create a new instance with updated values', () {
      final createdAt = DateTime(2024, 1, 15);
      final request = FriendRequest(
        requestId: 'req_123',
        fromUserId: 'user_123',
        fromUserName: 'Juan Pérez',
        toUserId: 'user_456',
        createdAt: createdAt,
      );

      final respondedAt = DateTime(2024, 1, 16);
      final updatedRequest = request.copyWith(
        status: 'accepted',
        respondedAt: respondedAt,
      );

      expect(updatedRequest.requestId, 'req_123');
      expect(updatedRequest.fromUserId, 'user_123');
      expect(updatedRequest.fromUserName, 'Juan Pérez');
      expect(updatedRequest.toUserId, 'user_456');
      expect(updatedRequest.createdAt, createdAt);
      expect(updatedRequest.status, 'accepted');
      expect(updatedRequest.respondedAt, respondedAt);
    });

    test('FriendRequest serialization and deserialization should be reversible', () {
      final createdAt = DateTime(2024, 1, 15);
      final respondedAt = DateTime(2024, 1, 16);
      final originalRequest = FriendRequest(
        requestId: 'req_123',
        fromUserId: 'user_123',
        fromUserName: 'Juan Pérez',
        fromUserEmail: 'juan@example.com',
        fromUserPhotoUrl: 'https://example.com/photo.jpg',
        toUserId: 'user_456',
        createdAt: createdAt,
        status: 'accepted',
        respondedAt: respondedAt,
      );

      final json = originalRequest.toJson();
      final deserializedRequest = FriendRequest.fromJson(json);

      expect(deserializedRequest.requestId, originalRequest.requestId);
      expect(deserializedRequest.fromUserId, originalRequest.fromUserId);
      expect(deserializedRequest.fromUserName, originalRequest.fromUserName);
      expect(deserializedRequest.fromUserEmail, originalRequest.fromUserEmail);
      expect(deserializedRequest.fromUserPhotoUrl, originalRequest.fromUserPhotoUrl);
      expect(deserializedRequest.toUserId, originalRequest.toUserId);
      expect(deserializedRequest.createdAt, originalRequest.createdAt);
      expect(deserializedRequest.status, originalRequest.status);
      expect(deserializedRequest.respondedAt, originalRequest.respondedAt);
    });

    test('FriendRequest should handle null respondedAt correctly', () {
      final createdAt = DateTime(2024, 1, 15);
      final json = {
        'requestId': 'req_123',
        'fromUserId': 'user_123',
        'fromUserName': 'Juan Pérez',
        'toUserId': 'user_456',
        'createdAt': createdAt.toIso8601String(),
        'status': 'pending',
      };

      final request = FriendRequest.fromJson(json);

      expect(request.respondedAt, null);
      expect(request.isPending, true);
    });
  });
}
