import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final List<String> participantIds;
  final String lastMessage;
  final String lastSenderId;
  final DateTime lastMessageAt;
  // Populated client-side from the other participant's user doc
  String otherUserName;
  String otherUserHandle;
  String otherUserAvatarUrl;

  ConversationModel({
    required this.id,
    required this.participantIds,
    required this.lastMessage,
    required this.lastSenderId,
    required this.lastMessageAt,
    this.otherUserName = '',
    this.otherUserHandle = '',
    this.otherUserAvatarUrl = '',
  });

  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ConversationModel(
      id: doc.id,
      participantIds: List<String>.from(d['participantIds'] ?? []),
      lastMessage: d['lastMessage'] ?? '',
      lastSenderId: d['lastSenderId'] ?? '',
      lastMessageAt:
          (d['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'participantIds': participantIds,
        'lastMessage': lastMessage,
        'lastSenderId': lastSenderId,
        'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      };
}

class MessageModel {
  final String id;
  final String senderId;
  final String content;
  final String? mediaUrl;
  final List<String> readBy;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    this.mediaUrl,
    required this.readBy,
    required this.createdAt,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: d['senderId'] ?? '',
      content: d['content'] ?? '',
      mediaUrl: d['mediaUrl'],
      readBy: List<String>.from(d['readBy'] ?? []),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'content': content,
        'mediaUrl': mediaUrl,
        'readBy': readBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}