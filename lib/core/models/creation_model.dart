// lib/core/models/creation_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class CreationModel {
  final String id;
  final String authorId;
  final String authorUsername;
  final String authorHandle;
  final String authorAvatarUrl;

  // "note" | "journal" | "prediction" | "collection"
  final String type;
  final String title;
  final String content;        // main body text
  final String? mediaUrl;      // optional cover photo
  final Map<String, dynamic> metadata; // type-specific structured data
  final bool isPublic;
  final DateTime createdAt;

  // Prediction poll fields (stored flat for easy querying)
  final List<Map<String, dynamic>> pollOptions; // [{label, votes}]
  final List<String> pollVoterIds;              // uids who already voted

  const CreationModel({
    required this.id,
    required this.authorId,
    required this.authorUsername,
    required this.authorHandle,
    this.authorAvatarUrl = '',
    required this.type,
    required this.title,
    required this.content,
    this.mediaUrl,
    required this.metadata,
    required this.isPublic,
    required this.createdAt,
    this.pollOptions = const [],
    this.pollVoterIds = const [],
  });

  factory CreationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CreationModel(
      id: doc.id,
      authorId: d['authorId'] ?? '',
      authorUsername: d['authorUsername'] ?? '',
      authorHandle: d['authorHandle'] ?? '',
      authorAvatarUrl: d['authorAvatarUrl'] ?? '',
      type: d['type'] ?? 'note',
      title: d['title'] ?? '',
      content: d['content'] ?? '',
      mediaUrl: d['mediaUrl'],
      metadata: Map<String, dynamic>.from(d['metadata'] ?? {}),
      isPublic: d['isPublic'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      pollOptions: (d['pollOptions'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      pollVoterIds: List<String>.from(d['pollVoterIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'authorId': authorId,
        'authorUsername': authorUsername,
        'authorHandle': authorHandle,
        'authorAvatarUrl': authorAvatarUrl,
        'type': type,
        'title': title,
        'content': content,
        'mediaUrl': mediaUrl,
        'metadata': metadata,
        'isPublic': isPublic,
        'createdAt': Timestamp.fromDate(createdAt),
        'pollOptions': pollOptions,
        'pollVoterIds': pollVoterIds,
      };

  CreationModel copyWith({bool? isPublic, List<Map<String, dynamic>>? pollOptions, List<String>? pollVoterIds}) =>
      CreationModel(
        id: id, authorId: authorId, authorUsername: authorUsername,
        authorHandle: authorHandle, authorAvatarUrl: authorAvatarUrl,
        type: type, title: title, content: content, mediaUrl: mediaUrl,
        metadata: metadata, createdAt: createdAt,
        isPublic: isPublic ?? this.isPublic,
        pollOptions: pollOptions ?? this.pollOptions,
        pollVoterIds: pollVoterIds ?? this.pollVoterIds,
      );

  int get totalVotes => pollOptions.fold(0, (sum, o) => sum + ((o['votes'] as int?) ?? 0));
}