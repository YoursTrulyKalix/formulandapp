// lib/features/feed/driver_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:formulandsocialapp/core/app_styles.dart';
import 'package:formulandsocialapp/core/data/f1_data.dart';
import 'package:formulandsocialapp/core/models/post_model.dart';
import 'package:formulandsocialapp/core/services/post_service.dart';

class DriverProfileScreen extends StatefulWidget {
  final F1Driver driver;
  const DriverProfileScreen({super.key, required this.driver});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  List<PostModel> _taggedPosts = [];
  bool _loadingPosts = true;

  @override
  void initState() {
    super.initState();
    _loadTaggedPosts();
  }

  Future<void> _loadTaggedPosts() async {
    try {
      final posts = await PostService.instance.getPostsByTag(widget.driver.code);
      if (mounted) setState(() { _taggedPosts = posts; _loadingPosts = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingPosts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver = widget.driver;
    final color = _hexToColor(driver.teamColor);

    return Scaffold(
      backgroundColor: AppStyles.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(driver, color),
          SliverToBoxAdapter(child: _buildBio(driver, color)),
          SliverToBoxAdapter(child: _buildStats(driver, color)),
          SliverToBoxAdapter(child: _buildFanPostsHeader(driver)),
          _buildFanPosts(),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(F1Driver driver, Color color) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppStyles.background,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Team color gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.3),
                    AppStyles.background,
                  ],
                ),
              ),
            ),
            // Diagonal racing stripes
            CustomPaint(painter: _StripesPainter(color)),
            // Driver number — giant watermark
            Positioned(
              right: -20,
              top: 20,
              child: Text(
                '#${driver.number}',
                style: TextStyle(
                  fontSize: 160,
                  fontWeight: FontWeight.w900,
                  color: color.withOpacity(0.08),
                  height: 1,
                ),
              ),
            ),
            // Driver info
            Positioned(
              bottom: 24,
              left: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Team badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color.withOpacity(0.5)),
                    ),
                    child: Text(
                      driver.team.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Driver name
                  Text(
                    driver.name,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppStyles.textMain,
                      letterSpacing: -1,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(driver.nationality, style: const TextStyle(color: AppStyles.textSub, fontSize: 13)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppStyles.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppStyles.borderColor),
                        ),
                        child: Text(
                          'Since ${driver.firstSeason}',
                          style: const TextStyle(color: AppStyles.textSub, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBio(F1Driver driver, Color color) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppStyles.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DRIVER BIO', style: AppStyles.label.copyWith(color: color)),
          const SizedBox(height: 10),
          Text(driver.bio, style: AppStyles.bodyText.copyWith(height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildStats(F1Driver driver, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CAREER STATS', style: AppStyles.label),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statCard('🏆', driver.championships, 'Championships', color)),
              const SizedBox(width: 10),
              Expanded(child: _statCard('🥇', driver.wins, 'Wins', color)),
              const SizedBox(width: 10),
              Expanded(child: _statCard('⚡', driver.poles, 'Pole Positions', color)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _statCard('🥂', driver.podiums, 'Podiums', color)),
              const SizedBox(width: 10),
              Expanded(child: _statCard('💨', driver.fastestLaps, 'Fastest Laps', color)),
              const SizedBox(width: 10),
              Expanded(child: Container()), // spacer
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppStyles.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppStyles.borderColor),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppStyles.textSub),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFanPostsHeader(F1Driver driver) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Text('FAN POSTS', style: AppStyles.label),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppStyles.accentRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppStyles.accentRed.withOpacity(0.3)),
            ),
            child: Text(
              '#${driver.code}',
              style: const TextStyle(color: AppStyles.accentRed, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFanPosts() {
    if (_loadingPosts) {
      return const SliverToBoxAdapter(
        child: Center(child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: AppStyles.accentRed, strokeWidth: 2),
        )),
      );
    }

    if (_taggedPosts.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppStyles.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppStyles.borderColor),
          ),
          child: Column(
            children: [
              const Icon(Icons.photo_outlined, color: AppStyles.textMuted, size: 32),
              const SizedBox(height: 10),
              Text(
                'No fan posts yet for #${widget.driver.code}.\nBe the first to post!',
                style: AppStyles.bodyText,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) => _FanPostTile(post: _taggedPosts[i]),
        childCount: _taggedPosts.length,
      ),
    );
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

// ── Fan Post Tile ─────────────────────────────────────────────────────────────

class _FanPostTile extends StatelessWidget {
  final PostModel post;
  const _FanPostTile({required this.post});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.cardDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38, height: 38,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppStyles.softGrey),
            child: Center(
              child: Text(
                post.authorUsername.isNotEmpty ? post.authorUsername[0].toUpperCase() : '?',
                style: const TextStyle(color: AppStyles.textMain, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(post.authorUsername, style: const TextStyle(color: AppStyles.textMain, fontWeight: FontWeight.w700, fontSize: 13)),
                    const Spacer(),
                    Text(_timeAgo(post.createdAt), style: const TextStyle(color: AppStyles.textMuted, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(post.content, style: AppStyles.bodyText),
                if (post.tags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: post.tags.map((t) => Text('#$t', style: const TextStyle(color: AppStyles.accentRed, fontSize: 11, fontWeight: FontWeight.w600))).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stripe Painter ────────────────────────────────────────────────────────────

class _StripesPainter extends CustomPainter {
  final Color color;
  _StripesPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.04)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width * 2; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x - size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}