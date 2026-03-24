import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:formulandsocialapp/core/models/user_model.dart';

class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ── Auth state stream ──────────────────────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;

  FirebaseFirestore get firestoreDb => _db;

  // ── Sign Up ────────────────────────────────────────────────────────────────
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    required String handle,
  }) async {
    // Create Firebase Auth account
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user!.uid;

    // Build the user document
    final newUser = UserModel(
      uid: uid,
      username: username,
      handle: handle.startsWith('@') ? handle : '@$handle',
      bio: '',
      avatarUrl: '',
      headerImageUrl: '',
      favouriteTeam: '',
      followersCount: 0,
      followingCount: 0,
      creationsCount: 0,
      createdAt: DateTime.now(),
    );

    // Write to Firestore
    await _db.collection('users').doc(uid).set(newUser.toMap());

    return newUser;
  }

  // ── Sign In ────────────────────────────────────────────────────────────────
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _fetchUserDoc(cred.user!.uid);
  }

  // ── Google Sign In ─────────────────────────────────────────────────────────
  Future<UserModel> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final cred = await _auth.signInWithCredential(credential);
    final uid = cred.user!.uid;

    // Create user doc if first-time sign in
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) {
      final handle = '@${googleUser.displayName?.replaceAll(' ', '_').toLowerCase() ?? uid.substring(0, 6)}';
      final newUser = UserModel(
        uid: uid,
        username: googleUser.displayName ?? 'F1 Fan',
        handle: handle,
        bio: '',
        avatarUrl: googleUser.photoUrl ?? '',
        headerImageUrl: '',
        favouriteTeam: '',
        followersCount: 0,
        followingCount: 0,
        creationsCount: 0,
        createdAt: DateTime.now(),
      );
      await _db.collection('users').doc(uid).set(newUser.toMap());
      return newUser;
    }

    return UserModel.fromFirestore(doc);
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // ── Get current user model ─────────────────────────────────────────────────
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _fetchUserDoc(user.uid);
  }

  // ── Internal helper ────────────────────────────────────────────────────────
  Future<UserModel> _fetchUserDoc(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) throw Exception('User document not found for uid: $uid');
    return UserModel.fromFirestore(doc);
  }
}