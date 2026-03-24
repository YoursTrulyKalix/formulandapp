// lib/core/models/post_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String authorUsername;
  final String authorHandle;
  final String authorAvatarUrl;
  final String type;           // "text" | "media"
  final String content;
  final List<String> mediaUrls; // up to 10 photos/videos
  final int likesCount;
  final int commentsCount;
  final List<String> tags;
  final DateTime createdAt;
  bool isLiked;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorUsername,
    required this.authorHandle,
    required this.authorAvatarUrl,
    required this.type,
    required this.content,
    this.mediaUrls = const [],
    required this.likesCount,
    required this.commentsCount,
    required this.tags,
    required this.createdAt,
    this.isLiked = false,
  });

  // Convenience — first media url for backward compat
  String? get mediaUrl => mediaUrls.isNotEmpty ? mediaUrls.first : null;
  bool get hasMedia => mediaUrls.isNotEmpty;

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      authorId: d['authorId'] ?? '',
      authorUsername: d['authorUsername'] ?? '',
      authorHandle: d['authorHandle'] ?? '',
      authorAvatarUrl: d['authorAvatarUrl'] ?? '',
      type: d['type'] ?? 'text',
      content: d['content'] ?? '',
      mediaUrls: List<String>.from(d['mediaUrls'] ?? []),
      likesCount: d['likesCount'] ?? 0,
      commentsCount: d['commentsCount'] ?? 0,
      tags: List<String>.from(d['tags'] ?? []),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'authorId': authorId,
        'authorUsername': authorUsername,
        'authorHandle': authorHandle,
        'authorAvatarUrl': authorAvatarUrl,
        'type': type,
        'content': content,
        'mediaUrls': mediaUrls,
        'likesCount': likesCount,
        'commentsCount': commentsCount,
        'tags': tags,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

// ── Comment Model ─────────────────────────────────────────────────────────────
class CommentModel {
  final String id;
  final String authorId;
  final String authorUsername;
  final String authorHandle;
  final String content;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.authorId,
    required this.authorUsername,
    required this.authorHandle,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      authorId: d['authorId'] ?? '',
      authorUsername: d['authorUsername'] ?? '',
      authorHandle: d['authorHandle'] ?? '',
      content: d['content'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'authorId': authorId,
        'authorUsername': authorUsername,
        'authorHandle': authorHandle,
        'content': content,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}