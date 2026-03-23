// lib/features/creations/creations_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:formulandsocialapp/core/app_styles.dart';
import 'package:formulandsocialapp/core/track_painter.dart';
import 'package:formulandsocialapp/core/models/creation_model.dart';
import 'package:formulandsocialapp/core/services/creation_service.dart';
import 'package:formulandsocialapp/features/creations/create_modal.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SORT OPTIONS
// ─────────────────────────────────────────────────────────────────────────────
enum _SortOption { newest, oldest, mostVoted, mostUsed }

extension _SortOptionLabel on _SortOption {
  String get label => switch (this) {
    _SortOption.newest   => 'Newest',
    _SortOption.oldest   => 'Oldest',
    _SortOption.mostVoted => 'Most Voted',
    _SortOption.mostUsed  => 'Most Used',
  };
  IconData get icon => switch (this) {
    _SortOption.newest   => Icons.arrow_downward_rounded,
    _SortOption.oldest   => Icons.arrow_upward_rounded,
    _SortOption.mostVoted => Icons.how_to_vote_rounded,
    _SortOption.mostUsed  => Icons.local_fire_department_rounded,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// CREATIONS SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class CreationsScreen extends StatefulWidget {
  const CreationsScreen({super.key});

  @override
  State<CreationsScreen> createState() => _CreationsScreenState();
}

class _CreationsScreenState extends State<CreationsScreen> {
  final _searchCtrl = TextEditingController();
  _SortOption _sort = _SortOption.newest;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() => setState(() {});

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CreationModel> _filtered(List<CreationModel> all) {
    // 1. Filter by search query
    final q = _searchCtrl.text.toLowerCase().trim();
    var list = q.isEmpty
        ? all
        : all.where((c) =>
            c.title.toLowerCase().contains(q) ||
            c.content.toLowerCase().contains(q) ||
            c.type.toLowerCase().contains(q)).toList();

    // 2. Sort
    list = List.of(list); // make mutable copy
    switch (_sort) {
      case _SortOption.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _SortOption.oldest:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case _SortOption.mostVoted:
        list.sort((a, b) => b.totalVotes.compareTo(a.totalVotes));
      case _SortOption.mostUsed:
        // itemCount for collections, totalVotes for predictions,
        // content.length as engagement proxy for notes/journals
        list.sort((a, b) => _usageScore(b).compareTo(_usageScore(a)));
    }
    return list;
  }

  int _usageScore(CreationModel c) => switch (c.type) {
    'collection' => (c.metadata['itemCount'] as int?) ?? 0,
    'prediction' => c.totalVotes,
    _            => c.content.length,
  };

  // ── Search bar + sort chips — extracted so they never live inside StreamBuilder
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: AppStyles.textMain, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by title or keyword…',
              hintStyle: const TextStyle(color: AppStyles.textMuted, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: AppStyles.textMuted, size: 18),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () => _searchCtrl.clear(),
                      child: const Icon(Icons.close_rounded, color: AppStyles.textMuted, size: 16),
                    )
                  : null,
              filled: true,
              fillColor: AppStyles.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppStyles.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppStyles.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppStyles.accentRed),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _SortOption.values.map((opt) {
                final active = _sort == opt;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _sort = opt),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: active ? AppStyles.accentRed : AppStyles.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active ? AppStyles.accentRed : AppStyles.borderColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(opt.icon, size: 12,
                              color: active ? Colors.white : AppStyles.textMuted),
                          const SizedBox(width: 5),
                          Text(opt.label,
                              style: TextStyle(
                                color: active ? Colors.white : AppStyles.textMuted,
                                fontSize: 12,
                                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                              )),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.background,
      body: Stack(
        children: [
          CustomPaint(size: Size.infinite, painter: TrackBackgroundPainter()),
          SafeArea(
            // Column keeps header + search bar OUTSIDE the StreamBuilder.
            // Only the list content below rebuilds when the stream emits.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('FORMULAND', style: AppStyles.label),
                        const SizedBox(height: 4),
                        Text('Garage', style: AppStyles.headingXL),
                      ]),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => showCreateModal(context),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: AppStyles.accentRed,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: AppStyles.accentRed.withOpacity(0.4),
                                blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Search + sort (stable — never rebuilds on stream/setState) ──
                _buildSearchBar(),

                // ── Stream content ──────────────────────────────────────────
                Expanded(
                  child: StreamBuilder<List<CreationModel>>(
                    stream: CreationService.instance.myCreationsStream(),
                    builder: (context, snapshot) {
                      final allCreations = snapshot.data ?? [];
                      final isLoading = snapshot.connectionState == ConnectionState.waiting;
                      final creations = _filtered(allCreations);

                      if (isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(color: AppStyles.accentRed, strokeWidth: 2),
                        );
                      }

                      if (allCreations.isEmpty) return _EmptyState();

                      return CustomScrollView(
                        slivers: [
                          // Stats row
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                              child: Row(children: [
                                Text(
                                  _searchCtrl.text.isNotEmpty
                                      ? '${creations.length} of ${allCreations.length} creation${allCreations.length == 1 ? '' : 's'}'
                                      : '${allCreations.length} creation${allCreations.length == 1 ? '' : 's'}',
                                  style: const TextStyle(color: AppStyles.textMuted, fontSize: 12),
                                ),
                                const SizedBox(width: 10),
                                Builder(builder: (_) {
                                  final n = allCreations.where((c) => c.isPublic).length;
                                  if (n == 0) return const SizedBox.shrink();
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppStyles.accentRed.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppStyles.accentRed.withOpacity(0.3)),
                                    ),
                                    child: Row(children: [
                                      const Icon(Icons.public_rounded, color: AppStyles.accentRed, size: 10),
                                      const SizedBox(width: 4),
                                      Text('$n public', style: const TextStyle(
                                          color: AppStyles.accentRed, fontSize: 10, fontWeight: FontWeight.w700)),
                                    ]),
                                  );
                                }),
                              ]),
                            ),
                          ),

                          // No results
                          if (creations.isEmpty && _searchCtrl.text.isNotEmpty)
                            SliverFillRemaining(
                              child: _NoSearchResults(
                                query: _searchCtrl.text,
                                onClear: () => _searchCtrl.clear(),
                              ),
                            ),

                          // Grid
                          if (creations.isNotEmpty)
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                              sliver: SliverGrid(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.78,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, i) => _CreationCard(
                                    creation: creations[i],
                                    onTap: () => Navigator.push(context,
                                      MaterialPageRoute(builder: (_) =>
                                          CreationDetailScreen(creation: creations[i]))),
                                  ),
                                  childCount: creations.length,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppStyles.surface, shape: BoxShape.circle,
                  border: Border.all(color: AppStyles.borderColor)),
              child: const Center(child: Text('🏎️', style: TextStyle(fontSize: 34))),
            ),
            const SizedBox(height: 20),
            const Text('Your Garage is empty',
                style: TextStyle(color: AppStyles.textMain, fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 8),
            const Text('Notes, journals, predictions\nand collections all live here.',
                style: AppStyles.bodyText, textAlign: TextAlign.center),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => showCreateModal(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: AppStyles.accentRed,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: AppStyles.accentRed.withOpacity(0.35),
                      blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: const Text('Start Creating',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NO SEARCH RESULTS
// ─────────────────────────────────────────────────────────────────────────────
class _NoSearchResults extends StatelessWidget {
  final String query;
  final VoidCallback onClear;
  const _NoSearchResults({required this.query, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: AppStyles.surface, shape: BoxShape.circle,
                  border: Border.all(color: AppStyles.borderColor)),
              child: const Center(child: Icon(Icons.search_off_rounded, color: AppStyles.textMuted, size: 28)),
            ),
            const SizedBox(height: 16),
            Text('No results for "$query"',
                style: const TextStyle(color: AppStyles.textMain, fontWeight: FontWeight.w800, fontSize: 16),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('Try a different title or keyword.',
                style: AppStyles.bodyText, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onClear,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppStyles.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppStyles.borderColor),
                ),
                child: const Text('Clear search',
                    style: TextStyle(color: AppStyles.textSub, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CREATION CARD — picture if photo, text+title if not
// ─────────────────────────────────────────────────────────────────────────────
class _CreationCard extends StatelessWidget {
  final CreationModel creation;
  final VoidCallback onTap;
  const _CreationCard({required this.creation, required this.onTap});

  // Respect user customisation; fall back to type default
  Color get _color => creation.accentColor != null
      ? Color(creation.accentColor!)
      : _typeColor(creation.type);
  String get _emoji => creation.coverEmoji ?? _typeEmoji(creation.type);
  String get _label => _typeLabel(creation.type);

  static Color _typeColor(String t) => switch (t) {
    'journal'    => const Color(0xFF3671C6),
    'prediction' => const Color(0xFFFF8000),
    'collection' => const Color(0xFF229971),
    _            => AppStyles.accentRed,
  };

  static String _typeEmoji(String t) => switch (t) {
    'journal'    => '📓',
    'prediction' => '🔮',
    'collection' => '📁',
    _            => '📝',
  };

  static String _typeLabel(String t) => switch (t) {
    'journal'    => 'Journal',
    'prediction' => 'Prediction',
    'collection' => 'Collection',
    _            => 'Note',
  };

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inDays > 30) return '${(d.inDays / 30).floor()}mo';
    if (d.inDays > 0) return '${d.inDays}d';
    if (d.inHours > 0) return '${d.inHours}h';
    return 'now';
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = creation.mediaUrl != null && creation.mediaUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppStyles.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: creation.isPublic ? _color.withOpacity(0.35) : AppStyles.borderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── TOP: photo OR colored text preview ─────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: hasPhoto
                    // Photo — full cover
                    ? Image.network(creation.mediaUrl!, fit: BoxFit.cover)
                    // No photo — show title + snippet on gradient
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_color.withOpacity(0.22), AppStyles.background],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_emoji, style: const TextStyle(fontSize: 26)),
                            const Spacer(),
                            Text(
                              creation.title,
                              style: const TextStyle(
                                color: AppStyles.textMain,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (creation.content.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                creation.content,
                                style: const TextStyle(color: AppStyles.textSub, fontSize: 11, height: 1.3),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
              ),
            ),

            // ── BOTTOM: author + meta ──────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _color.withOpacity(0.3)),
                      ),
                      child: Text(_label,
                          style: TextStyle(color: _color, fontSize: 9,
                              fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                    ),
                    const SizedBox(height: 6),

                    // Author name
                    Row(children: [
                      Container(
                        width: 18, height: 18,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: _color.withOpacity(0.2)),
                        child: Center(child: Text(
                          creation.authorUsername.isNotEmpty
                              ? creation.authorUsername[0].toUpperCase() : '?',
                          style: TextStyle(color: _color, fontSize: 9, fontWeight: FontWeight.w900),
                        )),
                      ),
                      const SizedBox(width: 5),
                      Expanded(child: Text(
                        creation.authorUsername,
                        style: const TextStyle(color: AppStyles.textSub, fontSize: 10, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      )),
                    ]),

                    const Spacer(),

                    // Time + public
                    Row(children: [
                      Text(_timeAgo(creation.createdAt),
                          style: const TextStyle(color: AppStyles.textMuted, fontSize: 10)),
                      if (creation.isPublic) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.public_rounded, color: AppStyles.textMuted, size: 10),
                      ],
                      if (creation.type == 'prediction' && creation.totalVotes > 0) ...[
                        const Spacer(),
                        Text('${creation.totalVotes} votes',
                            style: const TextStyle(color: AppStyles.textMuted, fontSize: 9)),
                      ],
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CREATION DETAIL SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class CreationDetailScreen extends StatefulWidget {
  final CreationModel creation;
  const CreationDetailScreen({super.key, required this.creation});

  @override
  State<CreationDetailScreen> createState() => _CreationDetailScreenState();
}

class _CreationDetailScreenState extends State<CreationDetailScreen> {
  late CreationModel _c;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _c = widget.creation;
  }

  // Respect user customisation; fall back to type default
  Color get _color => _c.accentColor != null
      ? Color(_c.accentColor!)
      : switch (_c.type) {
          'journal'    => const Color(0xFF3671C6),
          'prediction' => const Color(0xFFFF8000),
          'collection' => const Color(0xFF229971),
          _            => AppStyles.accentRed,
        };

  String get _emoji => _c.coverEmoji ?? switch (_c.type) {
    'journal'    => '📓',
    'prediction' => '🔮',
    'collection' => '📁',
    _            => '📝',
  };

  Future<void> _togglePublic() async {
    setState(() => _toggling = true);
    await CreationService.instance.togglePublic(_c);
    setState(() { _c = _c.copyWith(isPublic: !_c.isPublic); _toggling = false; });
  }

  Future<void> _vote(int index) async {
    await CreationService.instance.votePoll(_c, index);
    // Reload from Firestore to get updated counts
    // For now optimistically update
    final opts = _c.pollOptions.asMap().entries.map((e) {
      if (e.key == index) return {...e.value, 'votes': (e.value['votes'] as int? ?? 0) + 1};
      return e.value;
    }).toList();
    final voters = [..._c.pollVoterIds, 'me'];
    setState(() => _c = _c.copyWith(pollOptions: opts, pollVoterIds: voters));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.background,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            pinned: true,
            backgroundColor: AppStyles.background,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () => _confirmDelete(context),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                ),
              ),
            ],
            expandedHeight: 180,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_color.withOpacity(0.25), AppStyles.background],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(child: Text(_emoji, style: const TextStyle(fontSize: 64))),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _color.withOpacity(0.3)),
                    ),
                    child: Text(_c.type.toUpperCase(),
                        style: TextStyle(color: _color, fontSize: 10,
                            fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(_c.title, style: const TextStyle(
                      color: AppStyles.textMain, fontSize: 26,
                      fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(height: 6),

                  // Author + date
                  Row(children: [
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: _color.withOpacity(0.2)),
                      child: Center(child: Text(
                        _c.authorUsername.isNotEmpty ? _c.authorUsername[0].toUpperCase() : '?',
                        style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w900),
                      )),
                    ),
                    const SizedBox(width: 8),
                    Text(_c.authorUsername,
                        style: const TextStyle(color: AppStyles.textSub, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Text('·', style: const TextStyle(color: AppStyles.textMuted)),
                    const SizedBox(width: 8),
                    Text(_formatDate(_c.createdAt),
                        style: const TextStyle(color: AppStyles.textMuted, fontSize: 12)),
                  ]),

                  const SizedBox(height: 20),

                  // Public toggle
                  _DetailPublicToggle(isPublic: _c.isPublic, color: _color,
                      toggling: _toggling, onTap: _togglePublic),

                  const SizedBox(height: 24),

                  // Type content
                  if (_c.type == 'note')       _NoteDetail(creation: _c),
                  if (_c.type == 'journal')    _JournalDetail(creation: _c, color: _color),
                  if (_c.type == 'prediction') _PredictionDetail(creation: _c, color: _color, onVote: _vote),
                  if (_c.type == 'collection') _CollectionDetail(creation: _c, color: _color),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete creation?',
            style: TextStyle(color: AppStyles.textMain, fontWeight: FontWeight.w800)),
        content: const Text('This can\'t be undone.', style: AppStyles.bodyText),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppStyles.textSub))),
          TextButton(
            onPressed: () async {
              await CreationService.instance.deleteCreation(_c);
              if (context.mounted) { Navigator.pop(context); Navigator.pop(context); }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL — NOTE
// ─────────────────────────────────────────────────────────────────────────────
class _NoteDetail extends StatelessWidget {
  final CreationModel creation;
  const _NoteDetail({required this.creation});

  @override
  Widget build(BuildContext context) {
    return Text(creation.content,
        style: AppStyles.bodyText.copyWith(fontSize: 15, height: 1.75));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL — JOURNAL
// ─────────────────────────────────────────────────────────────────────────────
class _JournalDetail extends StatelessWidget {
  final CreationModel creation;
  final Color color;
  const _JournalDetail({required this.creation, required this.color});

  @override
  Widget build(BuildContext context) {
    final m = creation.metadata;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if ((m['circuit'] ?? '').isNotEmpty) _metaChip('🏁', m['circuit'], color),
      if ((m['qualiPole'] ?? '').isNotEmpty || (m['raceWinner'] ?? '').isNotEmpty) ...[
        const SizedBox(height: 14),
        Row(children: [
          if ((m['qualiPole'] ?? '').isNotEmpty)
            Expanded(child: _ResultBadge(label: 'Pole', value: m['qualiPole'], color: const Color(0xFFFFD700))),
          if ((m['qualiPole'] ?? '').isNotEmpty && (m['raceWinner'] ?? '').isNotEmpty)
            const SizedBox(width: 10),
          if ((m['raceWinner'] ?? '').isNotEmpty)
            Expanded(child: _ResultBadge(label: 'Winner', value: m['raceWinner'], color: color)),
        ]),
      ],
      _section('🗓️ Friday', m['friday'], color),
      _section('⚡ Saturday', m['saturday'], color),
      _section('🏎️ Race Day', m['race'], color),
      _section('💥 Standout Moment', m['standoutMoment'], color),
      _section('⭐ Verdict', m['verdict'], color),
    ]);
  }

  Widget _section(String title, String? text, Color color) {
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Text(text, style: AppStyles.bodyText.copyWith(height: 1.7)),
      ]),
    );
  }

  Widget _metaChip(String emoji, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(children: [
        Text(emoji), const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: AppStyles.textMain, fontWeight: FontWeight.w700, fontSize: 14)),
      ]),
    );
  }
}

class _ResultBadge extends StatelessWidget {
  final String label, value;
  final Color color;
  const _ResultBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(children: [
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL — PREDICTION POLL with pie chart
// ─────────────────────────────────────────────────────────────────────────────
class _PredictionDetail extends StatelessWidget {
  final CreationModel creation;
  final Color color;
  final ValueChanged<int> onVote;
  const _PredictionDetail({required this.creation, required this.color, required this.onVote});

  bool get _hasVoted => creation.pollVoterIds.contains('me') ||
      creation.totalVotes > 0 && creation.pollVoterIds.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final m = creation.metadata;
    final total = creation.totalVotes;
    final hasVotes = total > 0;
    final opts = creation.pollOptions;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Prediction summary cards
      if ((m['pole'] ?? '').isNotEmpty || (m['winner'] ?? '').isNotEmpty) ...[
        Row(children: [
          if ((m['pole'] ?? '').isNotEmpty)
            Expanded(child: _ResultBadge(label: '⚡ Pole', value: m['pole'], color: const Color(0xFFFFD700))),
          if ((m['pole'] ?? '').isNotEmpty && (m['winner'] ?? '').isNotEmpty)
            const SizedBox(width: 10),
          if ((m['winner'] ?? '').isNotEmpty)
            Expanded(child: _ResultBadge(label: '🏆 Winner', value: m['winner'], color: color)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          if ((m['p2'] ?? '').isNotEmpty)
            Expanded(child: _ResultBadge(label: '🥈 P2', value: m['p2'], color: const Color(0xFFC0C0C0))),
          if ((m['p2'] ?? '').isNotEmpty && (m['p3'] ?? '').isNotEmpty)
            const SizedBox(width: 10),
          if ((m['p3'] ?? '').isNotEmpty)
            Expanded(child: _ResultBadge(label: '🥉 P3', value: m['p3'], color: const Color(0xFFCD7F32))),
        ]),
      ],

      const SizedBox(height: 24),

      // Poll section
      Row(children: [
        const Icon(Icons.poll_rounded, color: AppStyles.accentRed, size: 16),
        const SizedBox(width: 8),
        Text('COMMUNITY POLL', style: AppStyles.label),
        const Spacer(),
        Text('$total vote${total == 1 ? '' : 's'}',
            style: const TextStyle(color: AppStyles.textMuted, fontSize: 12)),
      ]),
      const SizedBox(height: 14),

      // Pie chart if there are votes
      if (hasVotes) ...[
        _PollPieChart(options: opts, total: total, color: color),
        const SizedBox(height: 16),
      ],

      // Poll bars / vote buttons
      ...opts.asMap().entries.map((e) {
        final votes = (e.value['votes'] as int?) ?? 0;
        final pct = total > 0 ? votes / total : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: _hasVoted ? null : () => onVote(e.key),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppStyles.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _optionColor(e.key).withOpacity(0.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(e.value['label'] as String,
                      style: const TextStyle(color: AppStyles.textMain,
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  const Spacer(),
                  if (hasVotes)
                    Text('${(pct * 100).round()}%',
                        style: TextStyle(color: _optionColor(e.key),
                            fontWeight: FontWeight.w800, fontSize: 13)),
                ]),
                if (hasVotes) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: AppStyles.softGrey,
                      valueColor: AlwaysStoppedAnimation(_optionColor(e.key)),
                    ),
                  ),
                ],
              ]),
            ),
          ),
        );
      }),

      if (!_hasVoted && !hasVotes)
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text('Tap an option to cast your vote',
              style: TextStyle(color: AppStyles.textMuted, fontSize: 12)),
        ),

      // Reasoning
      if ((m['reasoning'] ?? '').isNotEmpty) ...[
        const SizedBox(height: 20),
        Text('💬 REASONING', style: AppStyles.label),
        const SizedBox(height: 8),
        Text(m['reasoning'], style: AppStyles.bodyText.copyWith(height: 1.7)),
      ],
    ]);
  }

  Color _optionColor(int i) {
    const colors = [Color(0xFFFFD700), AppStyles.accentRed, Color(0xFFC0C0C0), Color(0xFFCD7F32)];
    return colors[i % colors.length];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PIE CHART
// ─────────────────────────────────────────────────────────────────────────────
class _PollPieChart extends StatelessWidget {
  final List<Map<String, dynamic>> options;
  final int total;
  final Color color;
  const _PollPieChart({required this.options, required this.total, required this.color});

  static const _colors = [Color(0xFFFFD700), Color(0xFFE10600), Color(0xFFC0C0C0), Color(0xFFCD7F32)];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 160, height: 160,
        child: CustomPaint(
          painter: _PiePainter(
            slices: options.map((o) => (o['votes'] as int? ?? 0) / total).toList(),
            colors: _colors,
          ),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('$total', style: const TextStyle(
                  color: AppStyles.textMain, fontWeight: FontWeight.w900, fontSize: 22)),
              const Text('votes', style: TextStyle(color: AppStyles.textMuted, fontSize: 11)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _PiePainter extends CustomPainter {
  final List<double> slices;
  final List<Color> colors;
  const _PiePainter({required this.slices, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = math.min(cx, cy);
    double startAngle = -math.pi / 2;

    for (int i = 0; i < slices.length; i++) {
      if (slices[i] <= 0) continue;
      final sweep = slices[i] * 2 * math.pi;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r - 10),
        startAngle, sweep - 0.04, false, paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PiePainter old) => old.slices != slices;
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL — COLLECTION
// ─────────────────────────────────────────────────────────────────────────────
class _CollectionDetail extends StatelessWidget {
  final CreationModel creation;
  final Color color;
  const _CollectionDetail({required this.creation, required this.color});

  @override
  Widget build(BuildContext context) {
    final m = creation.metadata;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if ((m['theme'] ?? '').isNotEmpty) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(children: [
            Text('📁', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Text(m['theme'], style: const TextStyle(
                color: AppStyles.textMain, fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
        ),
        const SizedBox(height: 16),
      ],
      if ((m['description'] ?? '').isNotEmpty)
        Text(m['description'], style: AppStyles.bodyText.copyWith(height: 1.7)),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppStyles.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppStyles.borderColor),
        ),
        child: Row(children: [
          Icon(Icons.photo_library_outlined, color: color, size: 20),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${m['itemCount'] ?? 0} items',
                style: const TextStyle(color: AppStyles.textMain, fontWeight: FontWeight.w700, fontSize: 14)),
            const Text('Tap posts in the feed to add them here',
                style: TextStyle(color: AppStyles.textMuted, fontSize: 11)),
          ]),
        ]),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC TOGGLE (reused in detail)
// ─────────────────────────────────────────────────────────────────────────────
class _DetailPublicToggle extends StatelessWidget {
  final bool isPublic, toggling;
  final Color color;
  final VoidCallback onTap;
  const _DetailPublicToggle({required this.isPublic, required this.color,
      required this.toggling, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: toggling ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isPublic ? color.withOpacity(0.1) : AppStyles.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isPublic ? color.withOpacity(0.4) : AppStyles.borderColor),
        ),
        child: Row(children: [
          Icon(isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
              color: isPublic ? color : AppStyles.textMuted, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isPublic ? 'Public' : 'Private',
                style: TextStyle(color: isPublic ? color : AppStyles.textMain,
                    fontWeight: FontWeight.w700, fontSize: 13)),
            Text(isPublic ? 'Visible in feed and your profile' : 'Only you can see this',
                style: const TextStyle(color: AppStyles.textMuted, fontSize: 11)),
          ])),
          if (toggling)
            const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppStyles.accentRed))
          else
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 42, height: 24,
              decoration: BoxDecoration(
                color: isPublic ? color : AppStyles.softGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                alignment: isPublic ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.all(3),
                  width: 18, height: 18,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}