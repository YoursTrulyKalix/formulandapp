import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:formulandsocialapp/core/models/message_model.dart';
import 'package:formulandsocialapp/core/models/user_model.dart';

class MessageService {
  static final MessageService instance = MessageService._internal();
  MessageService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  // ── Get or Create Conversation ─────────────────────────────────────────────
  /// Returns an existing conversationId between current user and [otherUserId],
  /// or creates a new one if none exists.
  Future<String> getOrCreateConversation(String otherUserId) async {
    // Query for existing conversation containing both participant IDs
    final existing = await _db
        .collection('conversations')
        .where('participantIds', arrayContains: _uid)
        .get();

    for (final doc in existing.docs) {
      final participants = List<String>.from(doc['participantIds'] ?? []);
      if (participants.contains(otherUserId)) {
        return doc.id; // Found existing conversation
      }
    }

    // No existing conversation — create one
    final ref = _db.collection('conversations').doc();
    await ref.set({
      'participantIds': [_uid, otherUserId],
      'lastMessage': '',
      'lastSenderId': '',
      'lastMessageAt': Timestamp.now(),
    });

    return ref.id;
  }

  // ── Send Message ───────────────────────────────────────────────────────────
  Future<void> sendMessage(
    String conversationId,
    String content, {
    String? mediaUrl,
  }) async {
    final batch = _db.batch();

    // Add message to subcollection
    final msgRef = _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();

    batch.set(msgRef, {
      'senderId': _uid,
      'content': content,
      'mediaUrl': mediaUrl,
      'readBy': [_uid],
      'createdAt': Timestamp.now(),
    });

    // Update conversation's last message metadata
    final convoRef = _db.collection('conversations').doc(conversationId);
    batch.update(convoRef, {
      'lastMessage': content,
      'lastSenderId': _uid,
      'lastMessageAt': Timestamp.now(),
    });

    await batch.commit();
  }

  // ── Real-time Messages Stream ──────────────────────────────────────────────
  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(MessageModel.fromFirestore).toList());
  }

  // ── Conversations Stream (for messages list screen) ────────────────────────
  Stream<List<ConversationModel>> getConversations() {
    return _db
        .collection('conversations')
        .where('participantIds', arrayContains: _uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .asyncMap((snap) async {
      final convos = snap.docs.map(ConversationModel.fromFirestore).toList();

      // Populate other user info for each conversation
      for (final convo in convos) {
        final otherId = convo.participantIds.firstWhere(
          (id) => id != _uid,
          orElse: () => '',
        );
        if (otherId.isEmpty) continue;

        try {
          final userDoc = await _db.collection('users').doc(otherId).get();
          if (userDoc.exists) {
            final user = UserModel.fromFirestore(userDoc);
            convo.otherUserName = user.username;
            convo.otherUserHandle = user.handle;
            convo.otherUserAvatarUrl = user.avatarUrl;
          }
        } catch (_) {}
      }

      return convos;
    });
  }

  // ── Mark Message as Read ───────────────────────────────────────────────────
  Future<void> markAsRead(String conversationId, String messageId) async {
    await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({
      'readBy': FieldValue.arrayUnion([_uid]),
    });
  }

  // ── Check if message is unread ─────────────────────────────────────────────
  bool isUnread(MessageModel message) =>
      message.senderId != _uid && !message.readBy.contains(_uid);
}