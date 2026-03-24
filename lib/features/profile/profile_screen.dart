import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:formulandsocialapp/core/app_styles.dart';
import 'package:formulandsocialapp/core/models/user_model.dart';
import 'package:formulandsocialapp/core/models/post_model.dart';
import 'package:formulandsocialapp/core/services/auth_service.dart';
import 'package:formulandsocialapp/features/auth/login_screen.dart';
import 'package:formulandsocialapp/features/profile/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  List<PostModel> _userPosts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await AuthService.instance.getCurrentUser();

      // Removed .orderBy('createdAt') to avoid requiring a composite index.
      // Sorting is done in Dart instead.
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('authorId', isEqualTo: user?.uid)
          .get();

      final posts = postsSnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _user = user;
        _userPosts = posts;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile: $e';
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppStyles.surface,
        title: const Text(
          'Logout',
          style: TextStyle(
              color: AppStyles.textMain, fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: AppStyles.textSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppStyles.textSub)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout',
                style: TextStyle(
                    color: AppStyles.accentRed,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AuthService.instance.signOut();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Logout failed: $e')),
          );
        }
      }
    }
  }

  Future<void> _editProfile() async {
    if (_user == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(user: _user!),
      ),
    );

    if (result == true) {
      _loadUserData();
    }
  }

  Future<void> _shareProfile() async {
    if (_user == null) return;

    try {
      final profileLink = 'Check out ${_user!.username} on Formuland!\n\n'
          'Username: ${_user!.username}\n'
          'Handle: ${_user!.handle}\n'
          'Bio: ${_user!.bio.isNotEmpty ? _user!.bio : 'No bio yet'}\n\n'
          'Download Formuland to see their profile!';

      Clipboard.setData(ClipboardData(text: profileLink));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile link copied to clipboard!'),
            backgroundColor: AppStyles.accentRed,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy: $e'),
            backgroundColor: AppStyles.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _showMoreOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppStyles.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppStyles.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
              margin: const EdgeInsets.only(bottom: 24),
            ),
            ListTile(
              leading: const Icon(Icons.favorite_outline,
                  color: AppStyles.accentRed, size: 20),
              title: const Text(
                'Favorites',
                style: TextStyle(
                    color: AppStyles.textMain, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Added to favorites'),
                    backgroundColor: AppStyles.accentRed,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block,
                  color: AppStyles.accentRed, size: 20),
              title: const Text(
                'Block User',
                style: TextStyle(
                    color: AppStyles.textMain, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User blocked'),
                    backgroundColor: AppStyles.accentRed,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined,
                  color: AppStyles.accentRed, size: 20),
              title: const Text(
                'Report Profile',
                style: TextStyle(
                    color: AppStyles.textMain, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Report submitted'),
                    backgroundColor: AppStyles.accentRed,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppStyles.background,
        body: const Center(
          child: CircularProgressIndicator(color: AppStyles.accentRed),
        ),
      );
    }

    if (_error != null || _user == null) {
      return Scaffold(
        backgroundColor: AppStyles.background,
        body: Center(
          child: Text(
            _error ?? 'Failed to load profile',
            style: const TextStyle(color: AppStyles.accentRed),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppStyles.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: PopupMenuButton(
              icon: const Icon(Icons.menu,
                  color: AppStyles.textMain, size: 24),
              color: AppStyles.surface,
              elevation: 8,
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: _logout,
                  child: Row(
                    children: const [
                      Icon(Icons.logout,
                          color: AppStyles.accentRed, size: 18),
                      SizedBox(width: 12),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: AppStyles.accentRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 70),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _user!.username,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppStyles.textMain,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _user!.handle,
                    style: const TextStyle(
                        color: AppStyles.textSub, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  if (_user!.bio.isNotEmpty)
                    Text(_user!.bio, style: AppStyles.bodyText)
                  else
                    Text(
                      'No bio yet',
                      style: AppStyles.bodyText.copyWith(
                        color: AppStyles.textSub.withOpacity(0.5),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  const SizedBox(height: 20),
                  _buildStatRow(),
                  const SizedBox(height: 24),
                  _buildActionRow(),
                  const SizedBox(height: 28),
                  Text("WALL", style: AppStyles.label),
                  const SizedBox(height: 14),
                  _buildPostWall(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 220,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A0000), Color(0xFF0A0A0A)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: CustomPaint(painter: _RaceStripePainter()),
              ),
              if (_user!.favouriteTeam.isNotEmpty)
                Positioned(
                  top: 50,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppStyles.accentRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _user!.favouriteTeam.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                )
              else
                Positioned(
                  top: 50,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppStyles.accentRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "F1 FAN",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          bottom: -50,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: AppStyles.background,
              shape: BoxShape.circle,
            ),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppStyles.softGrey,
                border: Border.all(
                    color: AppStyles.accentRed.withOpacity(0.5), width: 2),
              ),
              child: _user!.avatarUrl.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        _user!.avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            _getInitials(_user!.username),
                            style: const TextStyle(
                              color: AppStyles.textMain,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        _getInitials(_user!.username),
                        style: const TextStyle(
                          color: AppStyles.textMain,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    return name
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join('');
  }

  Widget _buildStatRow() {
    return Row(
      children: [
        _ProfileStat(
            label: "Posts", value: _userPosts.length.toString()),
        Container(
          width: 1,
          height: 30,
          color: AppStyles.borderColor,
          margin: const EdgeInsets.symmetric(horizontal: 24),
        ),
        _ProfileStat(
            label: "Followers",
            value: _formatCount(_user!.followersCount)),
        Container(
          width: 1,
          height: 30,
          color: AppStyles.borderColor,
          margin: const EdgeInsets.symmetric(horizontal: 24),
        ),
        _ProfileStat(
            label: "Following",
            value: _formatCount(_user!.followingCount)),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000)
      return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _editProfile,
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppStyles.accentRed, Color(0xFFAA0400)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  "Edit Profile",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _shareProfile,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppStyles.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppStyles.borderColor),
            ),
            child: const Icon(Icons.share_outlined,
                color: AppStyles.textSub, size: 18),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _showMoreOptions,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppStyles.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppStyles.borderColor),
            ),
            child: const Icon(Icons.more_horiz,
                color: AppStyles.textSub, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildPostWall() {
    if (_userPosts.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Column(
            children: const [
              Icon(Icons.image_not_supported_outlined,
                  color: AppStyles.textSub, size: 48),
              SizedBox(height: 16),
              Text(
                'No posts yet',
                style: TextStyle(
                  color: AppStyles.textSub,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        final post = _userPosts[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppStyles.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppStyles.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post header
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppStyles.softGrey,
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(post.authorUsername),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppStyles.textMain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorUsername,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppStyles.textMain,
                            ),
                          ),
                          Text(
                            post.authorHandle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppStyles.textSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatTime(post.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppStyles.textSub,
                      ),
                    ),
                  ],
                ),
              ),

              // Post content
              if (post.content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    post.content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppStyles.textMain,
                      height: 1.5,
                    ),
                  ),
                ),

              // Post media
              if (post.mediaUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                if (post.mediaUrls.length == 1)
                  Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppStyles.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        post.mediaUrls[0],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.broken_image,
                                  color: AppStyles.textSub, size: 32),
                              SizedBox(height: 8),
                              Text(
                                'Failed to load image',
                                style: TextStyle(color: AppStyles.textSub),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: post.mediaUrls.length,
                      itemBuilder: (context, i) => Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: AppStyles.borderColor),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                post.mediaUrls[i],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppStyles.background,
                                  child: const Center(
                                    child: Icon(Icons.broken_image,
                                        color: AppStyles.textSub),
                                  ),
                                ),
                              ),
                            ),
                            if (i == post.mediaUrls.length - 1 &&
                                post.mediaUrls.length > 1)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppStyles.accentRed,
                                    borderRadius:
                                        BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '+${post.mediaUrls.length - 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],

              // Post stats
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.favorite_outline,
                        color: AppStyles.accentRed, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      post.likesCount.toString(),
                      style: const TextStyle(
                          color: AppStyles.textSub, fontSize: 12),
                    ),
                    const SizedBox(width: 20),
                    Icon(Icons.comment_outlined,
                        color: AppStyles.accentRed, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      post.commentsCount.toString(),
                      style: const TextStyle(
                          color: AppStyles.textSub, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }
}

class _ProfileStat extends StatelessWidget {
  final String label, value;
  const _ProfileStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppStyles.textMain,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppStyles.textSub, fontSize: 12),
        ),
      ],
    );
  }
}

class _RaceStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x + 60, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}