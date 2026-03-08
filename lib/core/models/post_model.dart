import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String authorUsername;
  final String authorHandle;
  final String authorAvatarUrl;
  final String type; // "photo" | "log" | "poll"
  final String content;
  final String? mediaUrl;
  final int likesCount;
  final int commentsCount;
  final List<String> tags;
  final DateTime createdAt;
  bool isLiked; // local state, not stored in Firestore

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorUsername,
    required this.authorHandle,
    required this.authorAvatarUrl,
    required this.type,
    required this.content,
    this.mediaUrl,
    required this.likesCount,
    required this.commentsCount,
    required this.tags,
    required this.createdAt,
    this.isLiked = false,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      authorId: d['authorId'] ?? '',
      authorUsername: d['authorUsername'] ?? '',
      authorHandle: d['authorHandle'] ?? '',
      authorAvatarUrl: d['authorAvatarUrl'] ?? '',
      type: d['type'] ?? 'log',
      content: d['content'] ?? '',
      mediaUrl: d['mediaUrl'],
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
        'mediaUrl': mediaUrl,
        'likesCount': likesCount,
        'commentsCount': commentsCount,
        'tags': tags,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  PostModel copyWith({int? likesCount, int? commentsCount, bool? isLiked}) =>
      PostModel(
        id: id,
        authorId: authorId,
        authorUsername: authorUsername,
        authorHandle: authorHandle,
        authorAvatarUrl: authorAvatarUrl,
        type: type,
        content: content,
        mediaUrl: mediaUrl,
        likesCount: likesCount ?? this.likesCount,
        commentsCount: commentsCount ?? this.commentsCount,
        tags: tags,
        createdAt: createdAt,
        isLiked: isLiked ?? this.isLiked,
      );
}

class CommentModel {
  final String id;
  final String authorId;
  final String authorHandle;
  final String authorAvatarUrl;
  final String content;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.authorId,
    required this.authorHandle,
    required this.authorAvatarUrl,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      authorId: d['authorId'] ?? '',
      authorHandle: d['authorHandle'] ?? '',
      authorAvatarUrl: d['authorAvatarUrl'] ?? '',
      content: d['content'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'authorId': authorId,
        'authorHandle': authorHandle,
        'authorAvatarUrl': authorAvatarUrl,
        'content': content,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}