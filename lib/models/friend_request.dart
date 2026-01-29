import 'package:hive/hive.dart';

part 'friend_request.g.dart';

/// Estados de una solicitud de amistad
enum FriendRequestStatus {
  pending,
  accepted,
  rejected,
}

/// Representa una solicitud de amistad
@HiveType(typeId: 16)
class FriendRequest extends HiveObject {
  @HiveField(0)
  String requestId; // ID único de la solicitud

  @HiveField(1)
  String fromUserId; // UID del usuario que envía la solicitud

  @HiveField(2)
  String fromUserName; // Nombre del usuario que envía

  @HiveField(3)
  String? fromUserEmail;

  @HiveField(4)
  String? fromUserPhotoUrl;

  @HiveField(5)
  String toUserId; // UID del usuario que recibe la solicitud

  @HiveField(6)
  DateTime createdAt; // Fecha de creación

  @HiveField(7)
  String status; // 'pending', 'accepted', 'rejected'

  @HiveField(8)
  DateTime? respondedAt; // Fecha de respuesta

  FriendRequest({
    required this.requestId,
    required this.fromUserId,
    required this.fromUserName,
    this.fromUserEmail,
    this.fromUserPhotoUrl,
    required this.toUserId,
    required this.createdAt,
    this.status = 'pending',
    this.respondedAt,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'fromUserId': fromUserId,
        'fromUserName': fromUserName,
        'fromUserEmail': fromUserEmail,
        'fromUserPhotoUrl': fromUserPhotoUrl,
        'toUserId': toUserId,
        'createdAt': createdAt.toIso8601String(),
        'status': status,
        'respondedAt': respondedAt?.toIso8601String(),
      };

  factory FriendRequest.fromJson(Map<String, dynamic> json) => FriendRequest(
        requestId: json['requestId'],
        fromUserId: json['fromUserId'],
        fromUserName: json['fromUserName'],
        fromUserEmail: json['fromUserEmail'],
        fromUserPhotoUrl: json['fromUserPhotoUrl'],
        toUserId: json['toUserId'],
        createdAt: DateTime.parse(json['createdAt']),
        status: json['status'] ?? 'pending',
        respondedAt: json['respondedAt'] != null
            ? DateTime.parse(json['respondedAt'])
            : null,
      );

  FriendRequest copyWith({
    String? requestId,
    String? fromUserId,
    String? fromUserName,
    String? fromUserEmail,
    String? fromUserPhotoUrl,
    String? toUserId,
    DateTime? createdAt,
    String? status,
    DateTime? respondedAt,
  }) {
    return FriendRequest(
      requestId: requestId ?? this.requestId,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      fromUserEmail: fromUserEmail ?? this.fromUserEmail,
      fromUserPhotoUrl: fromUserPhotoUrl ?? this.fromUserPhotoUrl,
      toUserId: toUserId ?? this.toUserId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}
