// lib/core/services/post_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:formulandsocialapp/core/models/post_model.dart';
import 'package:formulandsocialapp/core/services/notification_service.dart';

class PostService {
  static final PostService instance = PostService._internal();
  PostService._internal();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  // ── Create Post ────────────────────────────────────────────────────────────
  Future<PostModel> createPost({
    required String content,
    List<String> mediaUrls = const [],  // up to 10
    List<String> tags = const [],
  }) async {
    final userDoc = await _db.collection('users').doc(_uid).get();
    final u = userDoc.data()!;
    final ref = _db.collection('posts').doc();

    final post = PostModel(
      id: ref.id,
      authorId: _uid,
      authorUsername: u['username'] ?? '',
      authorHandle: u['handle'] ?? '',
      authorAvatarUrl: u['avatarUrl'] ?? '',
      type: mediaUrls.isNotEmpty ? 'media' : 'text',
      content: content,
      mediaUrls: mediaUrls.take(10).toList(), // enforce 10 max
      likesCount: 0,
      commentsCount: 0,
      tags: tags,
      createdAt: DateTime.now(),
    );

    await ref.set(post.toMap());
    return post;
  }

  // ── Smart Feed Stream ──────────────────────────────────────────────────────
  Stream<List<PostModel>> feedStream() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('following')
        .snapshots()
        .asyncMap((followSnap) async {
      final followingIds = followSnap.docs.map((d) => d.id).toList();
      List<PostModel> posts = [];

      if (followingIds.isNotEmpty) {
        final chunks = _chunk(followingIds, 30);
        for (final chunk in chunks) {
          final snap = await _db
              .collection('posts')
              .where('authorId', whereIn: chunk)
              .orderBy('createdAt', descending: true)
              .limit(30)
              .get();
          posts.addAll(snap.docs.map(PostModel.fromFirestore));
        }
        posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        posts = posts.take(30).toList();
      }

      // Fallback / suggested
      if (posts.length < 10) {
        final suggested = await _db
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .limit(20)
            .get();
        final extra = suggested.docs
            .map(PostModel.fromFirestore)
            .where((p) => !posts.any((existing) => existing.id == p.id))
            .toList();
        posts.addAll(extra);
      }

      // Populate isLiked
      for (final post in posts) {
        final likeDoc = await _db
            .collection('posts').doc(post.id)
            .collection('likes').doc(_uid).get();
        post.isLiked = likeDoc.exists;
      }

      return posts;
    });
  }

  // ── Like / Unlike ──────────────────────────────────────────────────────────
  Future<bool> toggleLike(String postId, bool currentlyLiked) async {
    final postRef = _db.collection('posts').doc(postId);
    final likeRef = postRef.collection('likes').doc(_uid);
    final batch = _db.batch();

    if (currentlyLiked) {
      batch.delete(likeRef);
      batch.update(postRef, {'likesCount': FieldValue.increment(-1)});
      await batch.commit();
      return false;
    } else {
      batch.set(likeRef, {'likedAt': Timestamp.now()});
      batch.update(postRef, {'likesCount': FieldValue.increment(1)});
      await batch.commit();

      // Send notification to post author
      final postDoc = await postRef.get();
      final postData = postDoc.data() as Map<String, dynamic>?;
      if (postData != null) {
        final authorId = postData['authorId'] as String? ?? '';
        final content = postData['content'] as String? ?? '';
        await NotificationService.instance.send(
          toUserId: authorId,
          type: 'like',
          postId: postId,
          postPreview: content.length > 50 ? '${content.substring(0, 50)}…' : content,
        );
      }
      return true;
    }
  }

  Future<bool> isLiked(String postId) async {
    final doc = await _db.collection('posts').doc(postId)
        .collection('likes').doc(_uid).get();
    return doc.exists;
  }

  // ── Comments ───────────────────────────────────────────────────────────────
  Future<void> addComment(String postId, String content) async {
    final userDoc = await _db.collection('users').doc(_uid).get();
    final u = userDoc.data()!;
    final batch = _db.batch();
    final commentRef = _db.collection('posts').doc(postId).collection('comments').doc();

    batch.set(commentRef, CommentModel(
      id: commentRef.id,
      authorId: _uid,
      authorUsername: u['username'] ?? '',
      authorHandle: u['handle'] ?? '',
      content: content,
      createdAt: DateTime.now(),
    ).toMap());

    batch.update(_db.collection('posts').doc(postId),
        {'commentsCount': FieldValue.increment(1)});
    await batch.commit();

    // Send notification
    final postDoc = await _db.collection('posts').doc(postId).get();
    final postData = postDoc.data() as Map<String, dynamic>?;
    if (postData != null) {
      final authorId = postData['authorId'] as String? ?? '';
      final postContent = postData['content'] as String? ?? '';
      await NotificationService.instance.send(
        toUserId: authorId,
        type: 'comment',
        postId: postId,
        postPreview: postContent.length > 50 ? '${postContent.substring(0, 50)}…' : postContent,
      );
    }
  }

  Stream<List<CommentModel>> commentsStream(String postId) {
    return _db
        .collection('posts').doc(postId).collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map(CommentModel.fromFirestore).toList());
  }

  // ── Posts by tag (driver profile) ─────────────────────────────────────────
  Future<List<PostModel>> getPostsByTag(String tag) async {
    final snap = await _db
        .collection('posts')
        .where('tags', arrayContains: tag)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();
    return snap.docs.map(PostModel.fromFirestore).toList();
  }

  // ── Delete ─────────────────────────────────────────────────────────────────
  Future<void> deletePost(String postId) async {
    await _db.collection('posts').doc(postId).delete();
  }

  List<List<T>> _chunk<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(i, (i + size).clamp(0, list.length)));
    }
    return chunks;
  }
}