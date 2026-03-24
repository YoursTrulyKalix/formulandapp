// lib/core/services/notification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:formulandsocialapp/core/models/notification_model.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference _notifs(String uid) =>
      _db.collection('users').doc(uid).collection('notifications');

  // ── Send a notification ────────────────────────────────────────────────────
  Future<void> send({
    required String toUserId,
    required String type,
    String? postId,
    String? postPreview,
  }) async {
    // Don't notify yourself
    if (toUserId == _uid) return;

    final userDoc = await _db.collection('users').doc(_uid).get();
    final d = userDoc.data() as Map<String, dynamic>? ?? {};
    final username = d['username'] ?? '';
    final handle = d['handle'] ?? '';

    final message = switch (type) {
      'like'      => '@$handle liked your post',
      'comment'   => '@$handle commented on your post',
      'follow'    => '@$handle started following you',
      'poll_vote' => '@$handle voted on your prediction',
      _           => '@$handle interacted with you',
    };

    await _notifs(toUserId).add(NotificationModel(
      id: '',
      toUserId: toUserId,
      fromUserId: _uid,
      fromUsername: username,
      fromHandle: handle,
      type: type,
      postId: postId,
      postPreview: postPreview,
      message: message,
      isRead: false,
      createdAt: DateTime.now(),
    ).toMap());
  }

  // ── Stream notifications for current user ──────────────────────────────────
  Stream<List<NotificationModel>> myNotificationsStream() {
    return _notifs(_uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map(NotificationModel.fromFirestore).toList());
  }

  // ── Unread count stream ────────────────────────────────────────────────────
  Stream<int> unreadCountStream() {
    return _notifs(_uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  // ── Mark all as read ───────────────────────────────────────────────────────
  Future<void> markAllRead() async {
    final snap = await _notifs(_uid).where('isRead', isEqualTo: false).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ── Mark single as read ────────────────────────────────────────────────────
  Future<void> markRead(String notifId) async {
    await _notifs(_uid).doc(notifId).update({'isRead': true});
  }
}