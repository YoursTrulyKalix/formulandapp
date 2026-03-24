// lib/core/models/notification_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// type: "like" | "comment" | "follow" | "poll_vote"
class NotificationModel {
  final String id;
  final String toUserId;       // recipient
  final String fromUserId;
  final String fromUsername;
  final String fromHandle;
  final String type;
  final String? postId;        // for like/comment
  final String? postPreview;   // short snippet of the post
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.toUserId,
    required this.fromUserId,
    required this.fromUsername,
    required this.fromHandle,
    required this.type,
    this.postId,
    this.postPreview,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      toUserId: d['toUserId'] ?? '',
      fromUserId: d['fromUserId'] ?? '',
      fromUsername: d['fromUsername'] ?? '',
      fromHandle: d['fromHandle'] ?? '',
      type: d['type'] ?? 'like',
      postId: d['postId'],
      postPreview: d['postPreview'],
      message: d['message'] ?? '',
      isRead: d['isRead'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'toUserId': toUserId,
        'fromUserId': fromUserId,
        'fromUsername': fromUsername,
        'fromHandle': fromHandle,
        'type': type,
        'postId': postId,
        'postPreview': postPreview,
        'message': message,
        'isRead': isRead,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  String get emoji => switch (type) {
    'like'      => '❤️',
    'comment'   => '💬',
    'follow'    => '👤',
    'poll_vote' => '🔮',
    _           => '🔔',
  };
}