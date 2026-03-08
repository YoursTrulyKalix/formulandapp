// lib/core/services/post_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:formulandsocialapp/core/models/post_model.dart';

class PostService {
  static final PostService instance = PostService._internal();
  PostService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  // ── Create Post ────────────────────────────────────────────────────────────
  Future<PostModel> createPost({
    required String type,
    required String content,
    String? mediaUrl,
    List<String> tags = const [],
  }) async {
    final userDoc = await _db.collection('users').doc(_uid).get();
    final userData = userDoc.data()!;

    final ref = _db.collection('posts').doc();
    final post = PostModel(
      id: ref.id,
      authorId: _uid,
      authorUsername: userData['username'] ?? '',
      authorHandle: userData['handle'] ?? '',
      authorAvatarUrl: userData['avatarUrl'] ?? '',
      type: type,
      content: content,
      mediaUrl: mediaUrl,
      likesCount: 0,
      commentsCount: 0,
      tags: tags,
      createdAt: DateTime.now(),
    );

    await ref.set(post.toMap());
    return post;
  }

  // ── Smart Feed Stream ──────────────────────────────────────────────────────
  // Shows posts from followed users. Falls back to all posts if not following anyone.
  Stream<List<PostModel>> feedStream() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('following')
        .snapshots()
        .asyncMap((followingSnap) async {
      final followingIds = followingSnap.docs.map((d) => d.id).toList();

      List<PostModel> posts = [];

      if (followingIds.isNotEmpty) {
        // ── Followed users feed ──────────────────────────────────────────
        // Firestore whereIn supports max 30 items
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

        // Sort merged results by date
        posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        posts = posts.take(30).toList();

        // ── Suggested fallback — add a few posts from non-followed users ──
        if (posts.length < 10) {
          final suggested = await _getSuggestedPosts(excludeIds: followingIds);
          posts.addAll(suggested);
        }
      } else {
        // ── Not following anyone — show all posts (suggested) ────────────
        posts = await _getSuggestedPosts(excludeIds: []);
      }

      // Populate isLiked for each post
      for (final post in posts) {
        final likeDoc = await _db
            .collection('posts')
            .doc(post.id)
            .collection('likes')
            .doc(_uid)
            .get();
        post.isLiked = likeDoc.exists;
      }

      return posts;
    });
  }

  // ── Suggested posts (global feed, exclude already-shown authors) ──────────
  Future<List<PostModel>> _getSuggestedPosts({
    required List<String> excludeIds,
    int limit = 20,
  }) async {
    Query query = _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    final snap = await query.get();
    return snap.docs
        .map(PostModel.fromFirestore)
        .where((p) => !excludeIds.contains(p.authorId))
        .toList();
  }

  // ── Get Posts by User ──────────────────────────────────────────────────────
  Future<List<PostModel>> getPostsByUser(String userId) async {
    final snap = await _db
        .collection('posts')
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map(PostModel.fromFirestore).toList();
  }

  // ── Get Posts by Tag (for driver profile fan posts) ────────────────────────
  Future<List<PostModel>> getPostsByTag(String tag) async {
    final snap = await _db
        .collection('posts')
        .where('tags', arrayContains: tag)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();
    return snap.docs.map(PostModel.fromFirestore).toList();
  }

  // ── Like Post ──────────────────────────────────────────────────────────────
  Future<void> likePost(String postId) async {
    final batch = _db.batch();
    final likeRef = _db.collection('posts').doc(postId).collection('likes').doc(_uid);
    batch.set(likeRef, {'likedAt': Timestamp.now()});
    batch.update(_db.collection('posts').doc(postId), {'likesCount': FieldValue.increment(1)});
    await batch.commit();
  }

  // ── Unlike Post ────────────────────────────────────────────────────────────
  Future<void> unlikePost(String postId) async {
    final batch = _db.batch();
    final likeRef = _db.collection('posts').doc(postId).collection('likes').doc(_uid);
    batch.delete(likeRef);
    batch.update(_db.collection('posts').doc(postId), {'likesCount': FieldValue.increment(-1)});
    await batch.commit();
  }

  // ── Toggle Like ────────────────────────────────────────────────────────────
  Future<bool> toggleLike(String postId, bool currentlyLiked) async {
    if (currentlyLiked) { await unlikePost(postId); return false; }
    else { await likePost(postId); return true; }
  }

  // ── Check if Liked ─────────────────────────────────────────────────────────
  Future<bool> isLiked(String postId) async {
    final doc = await _db.collection('posts').doc(postId).collection('likes').doc(_uid).get();
    return doc.exists;
  }

  // ── Delete Post ────────────────────────────────────────────────────────────
  Future<void> deletePost(String postId) async {
    await _db.collection('posts').doc(postId).delete();
  }

  // ── Add Comment ────────────────────────────────────────────────────────────
  Future<void> addComment(String postId, String content) async {
    final userDoc = await _db.collection('users').doc(_uid).get();
    final userData = userDoc.data()!;
    final batch = _db.batch();
    final commentRef = _db.collection('posts').doc(postId).collection('comments').doc();
    batch.set(commentRef, {
      'authorId': _uid,
      'authorHandle': userData['handle'] ?? '',
      'authorAvatarUrl': userData['avatarUrl'] ?? '',
      'content': content,
      'createdAt': Timestamp.now(),
    });
    batch.update(_db.collection('posts').doc(postId), {'commentsCount': FieldValue.increment(1)});
    await batch.commit();
  }

  // ── Get Comments Stream ────────────────────────────────────────────────────
  Stream<List<CommentModel>> commentsStream(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(CommentModel.fromFirestore).toList());
  }

  // ── Helper: chunk list for Firestore whereIn ───────────────────────────────
  List<List<T>> _chunk<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(i, i + size > list.length ? list.length : i + size));
    }
    return chunks;
  }
}