// lib/core/services/creation_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:formulandsocialapp/core/models/creation_model.dart';

class CreationService {
  static final CreationService instance = CreationService._internal();
  CreationService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference _private(String uid) =>
      _db.collection('users').doc(uid).collection('creations');
  CollectionReference get _public => _db.collection('creations');

  // ── Create ─────────────────────────────────────────────────────────────────
  Future<CreationModel> createCreation({
    required String type,
    required String title,
    required String content,
    String? mediaUrl,
    Map<String, dynamic> metadata = const {},
    bool isPublic = false,
    List<Map<String, dynamic>> pollOptions = const [],
  }) async {
    final userDoc = await _db.collection('users').doc(_uid).get();
    final userData = userDoc.data()!;
    final ref = _private(_uid).doc();

    final creation = CreationModel(
      id: ref.id,
      authorId: _uid,
      authorUsername: userData['username'] ?? '',
      authorHandle: userData['handle'] ?? '',
      authorAvatarUrl: userData['avatarUrl'] ?? '',
      type: type,
      title: title,
      content: content,
      mediaUrl: mediaUrl,
      metadata: metadata,
      isPublic: isPublic,
      createdAt: DateTime.now(),
      pollOptions: pollOptions,
      pollVoterIds: [],
    );

    final batch = _db.batch();
    batch.set(ref, creation.toMap());
    if (isPublic) batch.set(_public.doc(ref.id), creation.toMap());
    await batch.commit();
    return creation;
  }

  // ── Vote on poll ───────────────────────────────────────────────────────────
  Future<void> votePoll(CreationModel creation, int optionIndex) async {
    if (creation.pollVoterIds.contains(_uid)) return;

    final updatedOptions = creation.pollOptions.asMap().entries.map((e) {
      if (e.key == optionIndex) {
        return {...e.value, 'votes': ((e.value['votes'] as int?) ?? 0) + 1};
      }
      return e.value;
    }).toList();

    final updatedVoters = [...creation.pollVoterIds, _uid];

    final batch = _db.batch();
    batch.update(_private(creation.authorId).doc(creation.id), {
      'pollOptions': updatedOptions,
      'pollVoterIds': updatedVoters,
    });
    if (creation.isPublic) {
      batch.update(_public.doc(creation.id), {
        'pollOptions': updatedOptions,
        'pollVoterIds': updatedVoters,
      });
    }
    await batch.commit();
  }

  // ── Toggle public/private ──────────────────────────────────────────────────
  Future<void> togglePublic(CreationModel creation) async {
    final newPublic = !creation.isPublic;
    final batch = _db.batch();
    batch.update(_private(_uid).doc(creation.id), {'isPublic': newPublic});
    if (newPublic) {
      batch.set(_public.doc(creation.id), creation.copyWith(isPublic: true).toMap());
    } else {
      batch.delete(_public.doc(creation.id));
    }
    await batch.commit();
  }

  // ── Streams ────────────────────────────────────────────────────────────────
  Stream<List<CreationModel>> myCreationsStream() {
    return _private(_uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(CreationModel.fromFirestore).toList());
  }

  Stream<List<CreationModel>> publicCreationsByUser(String userId) {
    return _public
        .where('authorId', isEqualTo: userId)
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(CreationModel.fromFirestore).toList());
  }

  Stream<List<CreationModel>> publicFeedStream({int limit = 20}) {
    return _public
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(CreationModel.fromFirestore).toList());
  }

  // ── Delete ─────────────────────────────────────────────────────────────────
  Future<void> deleteCreation(CreationModel creation) async {
    final batch = _db.batch();
    batch.delete(_private(_uid).doc(creation.id));
    if (creation.isPublic) batch.delete(_public.doc(creation.id));
    await batch.commit();
  }
}