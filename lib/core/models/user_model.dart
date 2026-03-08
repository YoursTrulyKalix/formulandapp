import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;
  final String handle;
  final String bio;
  final String avatarUrl;
  final String headerImageUrl;
  final String favouriteTeam;
  final int followersCount;
  final int followingCount;
  final int creationsCount;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.username,
    required this.handle,
    required this.bio,
    required this.avatarUrl,
    required this.headerImageUrl,
    required this.favouriteTeam,
    required this.followersCount,
    required this.followingCount,
    required this.creationsCount,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      username: d['username'] ?? '',
      handle: d['handle'] ?? '',
      bio: d['bio'] ?? '',
      avatarUrl: d['avatarUrl'] ?? '',
      headerImageUrl: d['headerImageUrl'] ?? '',
      favouriteTeam: d['favouriteTeam'] ?? '',
      followersCount: d['followersCount'] ?? 0,
      followingCount: d['followingCount'] ?? 0,
      creationsCount: d['creationsCount'] ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'username': username,
        'handle': handle,
        'bio': bio,
        'avatarUrl': avatarUrl,
        'headerImageUrl': headerImageUrl,
        'favouriteTeam': favouriteTeam,
        'followersCount': followersCount,
        'followingCount': followingCount,
        'creationsCount': creationsCount,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  UserModel copyWith({
    String? username,
    String? handle,
    String? bio,
    String? avatarUrl,
    String? headerImageUrl,
    String? favouriteTeam,
    int? followersCount,
    int? followingCount,
    int? creationsCount,
  }) =>
      UserModel(
        uid: uid,
        username: username ?? this.username,
        handle: handle ?? this.handle,
        bio: bio ?? this.bio,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        headerImageUrl: headerImageUrl ?? this.headerImageUrl,
        favouriteTeam: favouriteTeam ?? this.favouriteTeam,
        followersCount: followersCount ?? this.followersCount,
        followingCount: followingCount ?? this.followingCount,
        creationsCount: creationsCount ?? this.creationsCount,
        createdAt: createdAt,
      );
}