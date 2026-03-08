// lib/features/feed/feed_screen.dart

import 'package:flutter/material.dart';
import 'package:formulandsocialapp/core/app_styles.dart';
import 'package:formulandsocialapp/core/track_painter.dart';
import 'package:formulandsocialapp/core/models/post_model.dart';
import 'package:formulandsocialapp/core/services/post_service.dart';
import 'package:formulandsocialapp/core/data/f1_data.dart';
import 'package:formulandsocialapp/features/feed/driver_profile_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  F1Race? _currentRace;
  bool _raceLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRaceData();
  }

  Future<void> _loadRaceData() async {
    final race = await F1DataService.instance.getCurrentOrNextRace();
    if (mounted) setState(() { _currentRace = race; _raceLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.background,
      body: Stack(
        children: [
          CustomPaint(size: Size.infinite, painter: TrackBackgroundPainter()),
          SafeArea(child: _buildBody()),
        ],
      ),
    );
  }

  // ── Single CustomScrollView — eliminates all nested scroll conflicts ─────────
  Widget _buildBody() {
    return StreamBuilder<List<PostModel>>(
      stream: PostService.instance.feedStream(),
      builder: (context, snapshot) {
        final posts = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final hasError = snapshot.hasError;

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [

            // ── Header ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: _buildHeader(),
              ),
            ),

            // ── Driver Story Row ────────────────────────────────────────────
            SliverToBoxAdapter(child: _buildDriverStoryRow()),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // ── Race Banner ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildRaceBanner(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Feed label ──────────────────────────────────────────────────
            if (!isLoading && !hasError && posts.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      Text("POSTS", style: AppStyles.label),
                      const SizedBox(width: 8),
                      Text('${posts.length} posts',
                          style: const TextStyle(color: AppStyles.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
              ),

            // ── Loading ─────────────────────────────────────────────────────
            if (isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppStyles.accentRed, strokeWidth: 2),
                ),
              ),

            // ── Error ───────────────────────────────────────────────────────
            if (hasError)
              SliverFillRemaining(
                child: Center(child: Text('Something went wrong.', style: AppStyles.bodyText)),
              ),

            // ── Empty state ─────────────────────────────────────────────────
            if (!isLoading && !hasError && posts.isEmpty)
              SliverFillRemaining(child: _buildEmptyFeed()),

            // ── Posts list ──────────────────────────────────────────────────
            if (!isLoading && !hasError && posts.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _FeedCard(post: posts[i]),
                    childCount: posts.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("FORMULAND", style: AppStyles.label),
            const SizedBox(height: 4),
            Text("Feed", style: AppStyles.headingXL),
          ],
        ),
        const Spacer(),
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppStyles.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppStyles.borderColor),
          ),
          child: const Icon(Icons.notifications_outlined, color: AppStyles.textSub, size: 20),
        ),
      ],
    );
  }

  // ── Driver Story Row — horizontal ListView with no parent conflict ───────────
  Widget _buildDriverStoryRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Row(
            children: [
              Text("DRIVERS", style: AppStyles.label),
              const Spacer(),
              const Text("2026 Grid", style: TextStyle(color: AppStyles.textMuted, fontSize: 11)),
            ],
          ),
        ),
        SizedBox(
          height: 92,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            // KEY FIX: ClampingScrollPhysics ensures horizontal scroll
            // works independently from the parent vertical CustomScrollView
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.only(left: 20, right: 20),
            itemCount: F1DataService.drivers.length,
            itemBuilder: (context, i) {
              final driver = F1DataService.drivers[i];
              final color = _hexToColor(driver.teamColor);
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DriverProfileScreen(driver: driver)),
                ),
                child: Container(
                  margin: const EdgeInsets.only(right: 14),
                  child: Column(
                    children: [
                      Container(
                        width: 58, height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [color.withOpacity(0.8), color.withOpacity(0.3)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: color, width: 2),
                          boxShadow: [
                            BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            driver.code,
                            style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w900,
                              color: Colors.white, letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(driver.code,
                          style: const TextStyle(fontSize: 10, color: AppStyles.textSub, fontWeight: FontWeight.w600)),
                      Text('#${driver.number}',
                          style: TextStyle(fontSize: 9, color: color.withOpacity(0.8), fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Race Banner ──────────────────────────────────────────────────────────────
  Widget _buildRaceBanner() {
    if (_raceLoading) {
      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppStyles.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppStyles.borderColor),
        ),
        child: const Center(
          child: SizedBox(width: 16, height: 16,
            child: CircularProgressIndicator(color: AppStyles.accentRed, strokeWidth: 2)),
        ),
      );
    }

    final race = _currentRace;
    if (race == null) return const SizedBox.shrink();
    if (race.isLive) return _LiveRaceBanner(race: race);
    return _UpcomingRaceBanner(race: race);
  }

  // ── Empty Feed ───────────────────────────────────────────────────────────────
  Widget _buildEmptyFeed() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppStyles.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppStyles.borderColor),
            ),
            child: const Icon(Icons.dynamic_feed_outlined, color: AppStyles.textMuted, size: 28),
          ),
          const SizedBox(height: 16),
          const Text("Your feed is empty",
              style: TextStyle(color: AppStyles.textMain, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 6),
          const Text(
            "Follow other fans or create your\nfirst post to get started.",
            style: AppStyles.bodyText, textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

// ── Live Race Banner ──────────────────────────────────────────────────────────

class _LiveRaceBanner extends StatefulWidget {
  final F1Race race;
  const _LiveRaceBanner({required this.race});

  @override
  State<_LiveRaceBanner> createState() => _LiveRaceBannerState();
}

class _LiveRaceBannerState extends State<_LiveRaceBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A0000), Color(0xFF2A0000)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyles.accentRed.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: AppStyles.accentRed.withOpacity(0.15), blurRadius: 20)],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: AppStyles.accentRed.withOpacity(0.5 + _pulse.value * 0.5),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppStyles.accentRed.withOpacity(_pulse.value * 0.5), blurRadius: 6)],
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text("LIVE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppStyles.accentRed, letterSpacing: 2)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.race.raceName,
                    style: const TextStyle(fontSize: 13, color: AppStyles.textMain, fontWeight: FontWeight.w700)),
                if (widget.race.currentLap != null && widget.race.totalLaps != null)
                  Text('Lap ${widget.race.currentLap}/${widget.race.totalLaps}',
                      style: const TextStyle(color: AppStyles.textSub, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppStyles.accentRed, size: 18),
        ],
      ),
    );
  }
}

// ── Upcoming Race Banner ──────────────────────────────────────────────────────

class _UpcomingRaceBanner extends StatelessWidget {
  final F1Race race;
  const _UpcomingRaceBanner({required this.race});

  String _countdown(DateTime raceDate) {
    final diff = raceDate.difference(DateTime.now());
    if (diff.isNegative) return 'Race finished';
    if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours % 24}h away';
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes % 60}m away';
    return '${diff.inMinutes}m away';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppStyles.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppStyles.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppStyles.accentRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppStyles.accentRed.withOpacity(0.3)),
            ),
            child: const Icon(Icons.flag_rounded, color: AppStyles.accentRed, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NEXT RACE', style: AppStyles.label.copyWith(fontSize: 9)),
                const SizedBox(height: 2),
                Text(race.raceName,
                    style: const TextStyle(color: AppStyles.textMain, fontWeight: FontWeight.w700, fontSize: 13)),
                Text(race.circuit,
                    style: const TextStyle(color: AppStyles.textSub, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppStyles.accentRed.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppStyles.accentRed.withOpacity(0.2)),
            ),
            child: Text(
              _countdown(race.raceDate),
              style: const TextStyle(color: AppStyles.accentRed, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feed Card ─────────────────────────────────────────────────────────────────

class _FeedCard extends StatefulWidget {
  final PostModel post;
  const _FeedCard({required this.post});

  @override
  State<_FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<_FeedCard> {
  late bool _liked;
  late int _likesCount;

  @override
  void initState() {
    super.initState();
    _liked = widget.post.isLiked;
    _likesCount = widget.post.likesCount;
    _checkLiked();
  }

  Future<void> _checkLiked() async {
    final liked = await PostService.instance.isLiked(widget.post.id);
    if (mounted) setState(() => _liked = liked);
  }

  Future<void> _toggleLike() async {
    final newLiked = await PostService.instance.toggleLike(widget.post.id, _liked);
    if (mounted) setState(() { _liked = newLiked; _likesCount += newLiked ? 1 : -1; });
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isPhoto = post.type == 'photo';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: isPhoto ? AppStyles.heroCardDecoration : AppStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppStyles.softGrey,
                    border: isPhoto
                        ? Border.all(color: AppStyles.accentRed.withOpacity(0.6), width: 1.5)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      post.authorUsername.isNotEmpty ? post.authorUsername[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppStyles.textMain, fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorUsername,
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppStyles.textMain, fontSize: 14)),
                      Text(post.authorHandle,
                          style: const TextStyle(color: AppStyles.textSub, fontSize: 12)),
                    ],
                  ),
                ),
                Text(_timeAgo(post.createdAt),
                    style: const TextStyle(color: AppStyles.textMuted, fontSize: 11)),
              ],
            ),
          ),

          // Media
          if (isPhoto)
            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppStyles.softGrey,
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF1E1E1E), Color(0xFF2A2A2A)],
                ),
              ),
              child: post.mediaUrl != null && post.mediaUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(post.mediaUrl!, fit: BoxFit.cover),
                    )
                  : const Center(child: Icon(Icons.image_outlined, color: AppStyles.textMuted, size: 32)),
            ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(post.content, style: AppStyles.bodyText),
          ),

          // Tags
          if (post.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                spacing: 6,
                children: post.tags
                    .map((tag) => Text('#$tag',
                        style: const TextStyle(
                            color: AppStyles.accentRed, fontSize: 12, fontWeight: FontWeight.w600)))
                    .toList(),
              ),
            ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleLike,
                  child: Row(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          key: ValueKey(_liked),
                          color: _liked ? AppStyles.accentRed : AppStyles.textSub,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('$_likesCount',
                          style: const TextStyle(color: AppStyles.textSub, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Row(children: [
                  const Icon(Icons.chat_bubble_outline_rounded, color: AppStyles.textSub, size: 18),
                  const SizedBox(width: 4),
                  Text('${post.commentsCount}',
                      style: const TextStyle(color: AppStyles.textSub, fontSize: 12)),
                ]),
                const SizedBox(width: 16),
                const Icon(Icons.share_outlined, color: AppStyles.textSub, size: 18),
                const Spacer(),
                const Icon(Icons.bookmark_border_rounded, color: AppStyles.textSub, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}