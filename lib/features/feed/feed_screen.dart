// lib/features/feed/feed_screen.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:formulandsocialapp/core/app_styles.dart';
import 'package:formulandsocialapp/core/track_painter.dart';
import 'package:formulandsocialapp/core/models/post_model.dart';
import 'package:formulandsocialapp/core/models/creation_model.dart';
import 'package:formulandsocialapp/core/models/notification_model.dart';
import 'package:formulandsocialapp/core/services/post_service.dart';
import 'package:formulandsocialapp/core/services/creation_service.dart';
import 'package:formulandsocialapp/core/services/notification_service.dart';
import 'package:formulandsocialapp/core/services/media_service.dart';
import 'package:formulandsocialapp/core/data/f1_data.dart';
import 'package:formulandsocialapp/features/feed/driver_profile_screen.dart';
import 'package:formulandsocialapp/features/feed/f1_calendar_screen.dart';
import 'package:formulandsocialapp/features/creations/creations_screen.dart';

// ── Media file wrapper (handles both native paths and web bytes) ─────────────
class _MediaFile {
  final String name;
  final String? path; // null for web
  final List<int>? bytes; // null for native
  final String mimeType;

  _MediaFile({
    required this.name,
    this.path,
    this.bytes,
    required this.mimeType,
  });

  bool get isVideo => ['video/mp4', 'video/quicktime', 'video/x-msvideo'].contains(mimeType);

  Future<List<int>> getBytes() async {
    if (bytes != null) return bytes!;
    if (path != null) return File(path!).readAsBytes();
    throw Exception('No file data available');
  }

  Future<File> toFile() async {
    if (path != null) return File(path!);
    if (bytes != null) {
      final tempDir = await Directory.systemTemp;
      final file = File('${tempDir.path}/$name');
      await file.writeAsBytes(bytes!);
      return file;
    }
    throw Exception('Cannot convert to File');
  }
}

// ── Feed item wrapper ─────────────────────────────────────────────────────────
class _FeedItem {
  final PostModel? post;
  final CreationModel? creation;
  DateTime get date => post?.createdAt ?? creation!.createdAt;
  _FeedItem.fromPost(this.post) : creation = null;
  _FeedItem.fromCreation(this.creation) : post = null;
}

// ─────────────────────────────────────────────────────────────────────────────
// FEED SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.background,
      floatingActionButton: _ComposeFAB(onPost: () => setState(() {})),
      body: Stack(
        children: [
          CustomPaint(size: Size.infinite, painter: TrackBackgroundPainter()),
          SafeArea(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return StreamBuilder<List<PostModel>>(
      stream: PostService.instance.feedStream(),
      builder: (context, postSnap) {
        return StreamBuilder<List<CreationModel>>(
          stream: CreationService.instance.publicFeedStream(),
          builder: (context, creationSnap) {
            final isLoading = postSnap.connectionState == ConnectionState.waiting ||
                creationSnap.connectionState == ConnectionState.waiting;

            final posts = postSnap.data ?? [];
            final creations = creationSnap.data ?? [];
            final items = [
              ...posts.map(_FeedItem.fromPost),
              ...creations.map(_FeedItem.fromCreation),
            ]..sort((a, b) => b.date.compareTo(a.date));

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: _buildHeader(context),
                  ),
                ),

                // Driver story row
                SliverToBoxAdapter(child: _buildDriverRow()),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),

                // Race banner — tappable
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _RaceBanner(),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                if (isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(
                        color: AppStyles.accentRed, strokeWidth: 2)),
                  ),

                if (!isLoading && items.isEmpty)
                  SliverFillRemaining(child: _buildEmpty()),

                if (!isLoading && items.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Row(children: [
                        Text('FEED', style: AppStyles.label),
                        const SizedBox(width: 8),
                        Text('${items.length} posts',
                            style: const TextStyle(color: AppStyles.textMuted, fontSize: 11)),
                      ]),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final item = items[i];
                          return item.post != null
                              ? _PostCard(post: item.post!)
                              : _CreationFeedCard(creation: item.creation!);
                        },
                        childCount: items.length,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  // ── Header with notification bell ─────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('FORMULAND', style: AppStyles.label),
          const SizedBox(height: 4),
          Text('Feed', style: AppStyles.headingXL),
        ]),
        const Spacer(),
        // Notification bell with badge
        StreamBuilder<int>(
          stream: NotificationService.instance.unreadCountStream(),
          builder: (context, snap) {
            final count = snap.data ?? 0;
            return GestureDetector(
              onTap: () => _showNotifications(context),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppStyles.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppStyles.borderColor),
                    ),
                    child: const Icon(Icons.notifications_outlined,
                        color: AppStyles.textSub, size: 20),
                  ),
                  if (count > 0)
                    Positioned(
                      top: -4, right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppStyles.accentRed,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Driver story row ───────────────────────────────────────────────────────
  Widget _buildDriverRow() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: Row(children: [
          Text('DRIVERS', style: AppStyles.label),
          const Spacer(),
          const Text('2026 Grid',
              style: TextStyle(color: AppStyles.textMuted, fontSize: 11)),
        ]),
      ),
      SizedBox(
        height: 92,
        child: ScrollConfiguration(
          behavior: _WebScrollBehavior(),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.only(left: 20, right: 20),
            itemCount: F1DataService.drivers.length,
            itemBuilder: (context, i) {
              final driver = F1DataService.drivers[i];
              final color = _hex(driver.teamColor);
              return GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => DriverProfileScreen(driver: driver))),
                child: Container(
                  margin: const EdgeInsets.only(right: 14),
                  child: Column(children: [
                    Container(
                      width: 58, height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.8), color.withOpacity(0.3)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: color, width: 2),
                        boxShadow: [BoxShadow(color: color.withOpacity(0.3),
                            blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Center(child: Text(driver.code,
                          style: const TextStyle(fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white, letterSpacing: 0.5))),
                    ),
                    const SizedBox(height: 6),
                    Text(driver.code, style: const TextStyle(fontSize: 10,
                        color: AppStyles.textSub, fontWeight: FontWeight.w600)),
                    Text('#${driver.number}', style: TextStyle(
                        fontSize: 9, color: color.withOpacity(0.8),
                        fontWeight: FontWeight.w700)),
                  ]),
                ),
              );
            },
          ),
        ),
      ),
    ]);
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(color: AppStyles.surface, shape: BoxShape.circle,
              border: Border.all(color: AppStyles.borderColor)),
          child: const Icon(Icons.dynamic_feed_outlined,
              color: AppStyles.textMuted, size: 28),
        ),
        const SizedBox(height: 16),
        const Text('Your feed is empty',
            style: TextStyle(color: AppStyles.textMain,
                fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 6),
        const Text('Follow other fans or create your\nfirst post to get started.',
            style: AppStyles.bodyText, textAlign: TextAlign.center),
      ]),
    );
  }

  // ── Notifications bottom sheet ─────────────────────────────────────────────
  void _showNotifications(BuildContext context) {
    NotificationService.instance.markAllRead();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _NotificationsSheet(),
    );
  }

  Color _hex(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPOSE FAB
// ─────────────────────────────────────────────────────────────────────────────
class _ComposeFAB extends StatelessWidget {
  final VoidCallback onPost;
  const _ComposeFAB({required this.onPost});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _PostComposer(onPost: onPost),
      ),
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: AppStyles.accentRed,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: AppStyles.accentRed.withOpacity(0.45),
                blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POST COMPOSER — text + up to 10 photos/videos
// ─────────────────────────────────────────────────────────────────────────────
class _PostComposer extends StatefulWidget {
  final VoidCallback onPost;
  const _PostComposer({required this.onPost});
  @override
  State<_PostComposer> createState() => _PostComposerState();
}

class _PostComposerState extends State<_PostComposer> {
  final _textCtrl = TextEditingController();
  final List<_MediaFile> _mediaFiles = []; // Media files with bytes/path support
  bool _posting = false;
  bool _uploading = false;

  /// Opens file picker to select photos and/or videos from device
  Future<void> _addMedia() async {
    if (_mediaFiles.length >= 10) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 10 photos/videos per post'),
          backgroundColor: AppStyles.accentRed,
        ),
      );
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.media,
        allowMultiple: true,
        withData: true, // Get bytes for web compatibility
      );
      
      if (result == null || result.files.isEmpty) {
        return;
      }

      // Validate total files
      final totalFiles = _mediaFiles.length + result.files.length;
      if (totalFiles > 10) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Can only add ${10 - _mediaFiles.length} more files'),
            backgroundColor: AppStyles.accentRed,
          ),
        );
        return;
      }

      // Convert picked files to MediaFile wrapper
      final newMediaFiles = <_MediaFile>[];
      for (final pf in result.files) {
        try {
          // On web, accessing path throws an error - get it safely
          String? filePath;
          try {
            filePath = pf.path;
          } catch (e) {
            filePath = null; // Web doesn't have path
          }
          
          // Validate file size
          final sizeInMb = (pf.size ?? 0) / (1024 * 1024);
          if (sizeInMb > 5) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('File "${pf.name}" exceeds 5MB limit'),
                backgroundColor: AppStyles.accentRed,
              ),
            );
            return;
          }

          final mimeType = pf.extension != null
              ? _getMimeType(pf.extension!)
              : 'image/jpeg';
          
          // Create MediaFile without accessing path directly
          final mediaFile = _MediaFile(
            name: pf.name,
            path: filePath, // Will be null on web, path on native
            bytes: pf.bytes, // Always available
            mimeType: mimeType,
          );
          
          newMediaFiles.add(mediaFile);
        } catch (e) {
          // Skip file on error
        }
      }
      
      if (newMediaFiles.isNotEmpty) {
        setState(() => _mediaFiles.addAll(newMediaFiles));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting files: $e'),
          backgroundColor: AppStyles.accentRed,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  /// Get MIME type from file extension
  String _getMimeType(String ext) {
    final lower = ext.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(lower)) {
      return 'image/$lower';
    }
    if (['mp4', 'mkv', 'webm', 'avi'].contains(lower)) {
      return 'video/$lower';
    }
    if (lower == 'mov') return 'video/quicktime';
    return 'application/octet-stream';
  }

  /// Uploads all media files to Firebase Storage, then creates the post
  Future<void> _post() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty && _mediaFiles.isEmpty) return;

    setState(() => _posting = true);
    try {
      // Get current user ID
      final userId = MediaService.getCurrentUserId();

      // Upload media files if any
      List<String> mediaUrls = [];
      if (_mediaFiles.isNotEmpty) {
        setState(() => _uploading = true);
        try {
          // Upload each file sequentially (avoid race conditions)
          for (int i = 0; i < _mediaFiles.length; i++) {
            final mf = _mediaFiles[i];
            final bytes = await mf.getBytes();
            final url = await MediaService.uploadMediaBytes(
              bytes,
              mf.name,
              userId,
            );
            mediaUrls.add(url);
          }
        } finally {
          setState(() => _uploading = false);
        }
      }

      // Create post with uploaded URLs
      if (!mounted) return;
      await PostService.instance.createPost(
        content: text,
        mediaUrls: mediaUrls,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onPost();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _posting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppStyles.accentRed,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void dispose() { _textCtrl.dispose(); super.dispose(); }

  /// Check if a file is a video based on MIME type
  bool _isVideoFile(_MediaFile mf) => mf.isVideo;

  /// Build a video thumbnail display with play icon
  Widget _buildVideoThumbnail() {
    return Container(
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Placeholder for video (just a dark background)
          Container(color: AppStyles.surface),
          // Play button overlay
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, color: Color(0xFF111111), size: 20),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: AppStyles.borderColor,
                  borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 16),

            // Title row
            Row(children: [
              const Text('📝', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text('New Post', style: TextStyle(color: AppStyles.textMain,
                  fontWeight: FontWeight.w800, fontSize: 18)),
              const Spacer(),
              GestureDetector(
                onTap: _posting ? null : _post,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: _textCtrl.text.isNotEmpty || _mediaFiles.isNotEmpty
                        ? AppStyles.accentRed : AppStyles.softGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _posting
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Post', style: TextStyle(color: Colors.white,
                            fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // Text field
            TextField(
              controller: _textCtrl,
              maxLines: 5,
              autofocus: true,
              style: const TextStyle(color: AppStyles.textMain, fontSize: 15),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'What\'s happening on the grid? 🏎️',
                hintStyle: const TextStyle(color: AppStyles.textMuted, fontSize: 14),
                filled: true,
                fillColor: AppStyles.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppStyles.borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppStyles.borderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppStyles.accentRed)),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 12),

            // Media preview grid
            if (_mediaFiles.isNotEmpty) ...[
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _mediaFiles.length + (_mediaFiles.length < 10 ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == _mediaFiles.length) {
                      return _AddMediaBtn(onTap: _addMedia);
                    }
                    final mediaFile = _mediaFiles[i];
                    final isVideo = _isVideoFile(mediaFile);
                    return Stack(
                      children: [
                        Container(
                          width: 80, height: 80,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppStyles.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppStyles.borderColor),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: isVideo
                                ? _buildVideoThumbnail()
                                : (mediaFile.path != null
                                    ? Image.file(File(mediaFile.path!), fit: BoxFit.cover)
                                    : Image.memory(Uint8List.fromList(mediaFile.bytes ?? []), fit: BoxFit.cover)),
                          ),
                        ),
                        // Upload progress or delete button
                        if (_uploading)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                color: Colors.black54,
                                child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          Positioned(
                            top: 4, right: 12,
                            child: GestureDetector(
                              onTap: () => setState(() => _mediaFiles.removeAt(i)),
                              child: Container(
                                width: 20, height: 20,
                                decoration: const BoxDecoration(
                                  color: Colors.black54, shape: BoxShape.circle),
                                child: const Icon(Icons.close, color: Colors.white, size: 12),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Bottom toolbar
            Row(children: [
              // Add media button (when no media yet)
              if (_mediaFiles.isEmpty)
                GestureDetector(
                  onTap: _uploading || _posting ? null : _addMedia,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppStyles.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppStyles.borderColor),
                    ),
                    child: Row(children: [
                      const Icon(Icons.photo_library_outlined,
                          color: AppStyles.textSub, size: 18),
                      const SizedBox(width: 6),
                      const Text('Photo / Video',
                          style: TextStyle(color: AppStyles.textSub,
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              const Spacer(),
              // Media count indicator & upload status
              if (_mediaFiles.isNotEmpty) ...[
                if (_uploading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: AppStyles.textMuted,
                      strokeWidth: 2,
                    ),
                  )
                else
                  Text('${_mediaFiles.length}/10 media',
                      style: const TextStyle(color: AppStyles.textMuted, fontSize: 12)),
              ],
            ]),
          ],
        ),
      ),
    );
  }
}

class _AddMediaBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _AddMediaBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80, height: 80,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: AppStyles.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppStyles.borderColor, style: BorderStyle.solid),
        ),
        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add_photo_alternate_outlined, color: AppStyles.textMuted, size: 24),
          SizedBox(height: 4),
          Text('Add', style: TextStyle(color: AppStyles.textMuted, fontSize: 10)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RACE BANNER — tappable, opens calendar screen
// ─────────────────────────────────────────────────────────────────────────────
class _RaceBanner extends StatelessWidget {
  const _RaceBanner();

  String _countdown(DateTime d) {
    final diff = d.difference(DateTime.now());
    if (diff.isNegative) return 'Finished';
    if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes % 60}m';
    return '${diff.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final live = F1DataService.instance.getLiveRace();
    final next = F1DataService.instance.getNextRace();
    final race = live ?? next;
    if (race == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const F1CalendarScreen())),
      child: live != null
          ? _LiveBanner(race: live)
          : _UpcomingBanner(race: next!, countdown: _countdown(next.raceDate)),
    );
  }
}

class _LiveBanner extends StatefulWidget {
  final F1Race race;
  const _LiveBanner({required this.race});
  @override
  State<_LiveBanner> createState() => _LiveBannerState();
}

class _LiveBannerState extends State<_LiveBanner>
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
        gradient: const LinearGradient(
            colors: [Color(0xFF1A0000), Color(0xFF2A0000)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyles.accentRed.withOpacity(0.5)),
        boxShadow: [BoxShadow(
            color: AppStyles.accentRed.withOpacity(0.15), blurRadius: 20)],
      ),
      child: Row(children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) => Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: AppStyles.accentRed.withOpacity(0.5 + _pulse.value * 0.5),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                  color: AppStyles.accentRed.withOpacity(_pulse.value * 0.5),
                  blurRadius: 6)],
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Text('LIVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900,
            color: AppStyles.accentRed, letterSpacing: 2)),
        const SizedBox(width: 12),
        Text(widget.race.flagEmoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(child: Text(widget.race.raceName,
            style: const TextStyle(fontSize: 13, color: AppStyles.textMain,
                fontWeight: FontWeight.w700))),
        const Icon(Icons.chevron_right, color: AppStyles.accentRed, size: 18),
      ]),
    );
  }
}

class _UpcomingBanner extends StatelessWidget {
  final F1Race race;
  final String countdown;
  const _UpcomingBanner({required this.race, required this.countdown});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppStyles.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppStyles.borderColor),
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: AppStyles.accentRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppStyles.accentRed.withOpacity(0.3)),
          ),
          child: Center(child: Text(race.flagEmoji,
              style: const TextStyle(fontSize: 18))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('ROUND ${race.round}',
                style: AppStyles.label.copyWith(fontSize: 9)),
            if (race.isSprint) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8000).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('SPRINT', style: TextStyle(
                    color: Color(0xFFFF8000), fontSize: 8,
                    fontWeight: FontWeight.w800, letterSpacing: 0.8)),
              ),
            ],
          ]),
          const SizedBox(height: 2),
          Text(race.raceName, style: const TextStyle(color: AppStyles.textMain,
              fontWeight: FontWeight.w700, fontSize: 13)),
          Text(race.circuit, style: const TextStyle(
              color: AppStyles.textSub, fontSize: 11)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppStyles.accentRed.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppStyles.accentRed.withOpacity(0.2)),
            ),
            child: Text(countdown, style: const TextStyle(
                color: AppStyles.accentRed, fontSize: 11,
                fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 4),
          const Text('Tap for full schedule',
              style: TextStyle(color: AppStyles.textMuted, fontSize: 9)),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POST CARD — regular user post
// ─────────────────────────────────────────────────────────────────────────────
class _PostCard extends StatefulWidget {
  final PostModel post;
  const _PostCard({required this.post});
  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  late bool _liked;
  late int _likesCount;
  late int _commentsCount;

  @override
  void initState() {
    super.initState();
    _liked = widget.post.isLiked;
    _likesCount = widget.post.likesCount;
    _commentsCount = widget.post.commentsCount;
    _checkLiked();
  }

  Future<void> _checkLiked() async {
    final liked = await PostService.instance.isLiked(widget.post.id);
    if (mounted) setState(() => _liked = liked);
  }

  Future<void> _toggleLike() async {
    final newLiked = await PostService.instance.toggleLike(widget.post.id, _liked);
    if (mounted) setState(() {
      _liked = newLiked;
      _likesCount += newLiked ? 1 : -1;
    });
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CommentsSheet(
        postId: widget.post.id,
        onCommentAdded: () => setState(() => _commentsCount++),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppStyles.cardDecoration,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Author
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            _Avatar(username: post.authorUsername, size: 40),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(post.authorUsername, style: const TextStyle(color: AppStyles.textMain,
                  fontWeight: FontWeight.w800, fontSize: 14)),
              Text(post.authorHandle, style: const TextStyle(
                  color: AppStyles.textSub, fontSize: 12)),
            ])),
            Text(_timeAgo(post.createdAt),
                style: const TextStyle(color: AppStyles.textMuted, fontSize: 11)),
          ]),
        ),

        // Content
        if (post.content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Text(post.content, style: AppStyles.bodyText),
          ),

        // Media grid (up to 10)
        if (post.hasMedia) _MediaGrid(urls: post.mediaUrls),

        // Tags
        if (post.tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Wrap(spacing: 6, children: post.tags.map((t) =>
                Text('#$t', style: const TextStyle(color: AppStyles.accentRed,
                    fontSize: 12, fontWeight: FontWeight.w600))).toList()),
          ),

        // Actions
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
          child: Row(children: [
            // Like
            GestureDetector(
              onTap: _toggleLike,
              child: Row(children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    key: ValueKey(_liked),
                    color: _liked ? AppStyles.accentRed : AppStyles.textSub,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 4),
                Text('$_likesCount', style: const TextStyle(
                    color: AppStyles.textSub, fontSize: 13)),
              ]),
            ),
            const SizedBox(width: 18),
            // Comment
            GestureDetector(
              onTap: _openComments,
              child: Row(children: [
                const Icon(Icons.chat_bubble_outline_rounded,
                    color: AppStyles.textSub, size: 20),
                const SizedBox(width: 4),
                Text('$_commentsCount', style: const TextStyle(
                    color: AppStyles.textSub, fontSize: 13)),
              ]),
            ),
            const SizedBox(width: 18),
            const Icon(Icons.share_outlined, color: AppStyles.textSub, size: 20),
            const Spacer(),
            const Icon(Icons.bookmark_border_rounded,
                color: AppStyles.textSub, size: 20),
          ]),
        ),
      ]),
    );
  }
}

// ── Media grid — supports 1-10 photos/videos ─────────────────────────────────
class _MediaGrid extends StatelessWidget {
  final List<String> urls;
  const _MediaGrid({required this.urls});

  @override
  Widget build(BuildContext context) {
    if (urls.length == 1) {
      return _mediaItem(urls[0], height: 220);
    }
    if (urls.length == 2) {
      return Row(children: urls.map((u) =>
          Expanded(child: _mediaItem(u, height: 180))).toList());
    }
    // 3+ — show 2 column grid, last item shows "+N more" if > 4
    final show = urls.take(4).toList();
    final more = urls.length - 4;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 2, crossAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: show.length,
      itemBuilder: (_, i) {
        final isLast = i == 3 && more > 0;
        return Stack(fit: StackFit.expand, children: [
          _mediaItem(show[i], height: null),
          if (isLast)
            Container(
              color: Colors.black54,
              child: Center(child: Text('+$more',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 24, fontWeight: FontWeight.w900))),
            ),
        ]);
      },
    );
  }

  Widget _mediaItem(String url, {double? height}) {
    return Container(
      height: height,
      color: AppStyles.softGrey,
      child: Image.network(url, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image_outlined, color: AppStyles.textMuted)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMMENTS BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _CommentsSheet extends StatefulWidget {
  final String postId;
  final VoidCallback onCommentAdded;
  const _CommentsSheet({required this.postId, required this.onCommentAdded});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    await PostService.instance.addComment(widget.postId, text);
    _ctrl.clear();
    widget.onCommentAdded();
    if (mounted) setState(() => _sending = false);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
        ),
        child: Column(children: [
          // Handle + header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(children: [
              Center(child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: AppStyles.borderColor,
                    borderRadius: BorderRadius.circular(2)),
              )),
              const SizedBox(height: 14),
              Row(children: [
                Text('Comments', style: AppStyles.headingL),
              ]),
              const Divider(color: Color(0xFF2A2A2A), height: 20),
            ]),
          ),

          // Comments list
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: PostService.instance.commentsStream(widget.postId),
              builder: (context, snap) {
                final comments = snap.data ?? [];
                if (comments.isEmpty) {
                  return const Center(
                    child: Text('No comments yet.\nBe the first!',
                        style: AppStyles.bodyText, textAlign: TextAlign.center),
                  );
                }
                return ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: comments.length,
                  itemBuilder: (_, i) => _CommentTile(comment: comments[i]),
                );
              },
            ),
          ),

          // Input
          Padding(
            padding: EdgeInsets.only(
              left: 16, right: 16, bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
              top: 8,
            ),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  style: const TextStyle(color: AppStyles.textMain, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Add a comment…',
                    hintStyle: const TextStyle(color: AppStyles.textMuted),
                    filled: true, fillColor: AppStyles.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppStyles.borderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppStyles.borderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppStyles.accentRed)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _sending ? null : _send,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppStyles.accentRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _sending
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommentModel comment;
  const _CommentTile({required this.comment});

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Avatar(username: comment.authorUsername, size: 34),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(comment.authorUsername, style: const TextStyle(
                color: AppStyles.textMain, fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(width: 8),
            Text(_timeAgo(comment.createdAt),
                style: const TextStyle(color: AppStyles.textMuted, fontSize: 11)),
          ]),
          const SizedBox(height: 4),
          Text(comment.content, style: AppStyles.bodyText),
        ])),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFICATIONS SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(children: [
              Center(child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: AppStyles.borderColor,
                    borderRadius: BorderRadius.circular(2)),
              )),
              const SizedBox(height: 14),
              Row(children: [
                Text('Notifications', style: AppStyles.headingL),
              ]),
              const Divider(color: Color(0xFF2A2A2A), height: 20),
            ]),
          ),
          Expanded(
            child: StreamBuilder<List<NotificationModel>>(
              stream: NotificationService.instance.myNotificationsStream(),
              builder: (context, snap) {
                final notifs = snap.data ?? [];
                if (notifs.isEmpty) {
                  return const Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('🔔', style: TextStyle(fontSize: 40)),
                      SizedBox(height: 12),
                      Text('No notifications yet',
                          style: TextStyle(color: AppStyles.textMain,
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      SizedBox(height: 6),
                      Text('When someone likes or comments\non your posts, you\'ll see it here.',
                          style: AppStyles.bodyText, textAlign: TextAlign.center),
                    ]),
                  );
                }
                return ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: notifs.length,
                  itemBuilder: (_, i) => _NotifTile(notif: notifs[i]),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotificationModel notif;
  const _NotifTile({required this.notif});

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: notif.isRead ? AppStyles.surface : AppStyles.accentRed.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: notif.isRead ? AppStyles.borderColor : AppStyles.accentRed.withOpacity(0.2),
        ),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Emoji icon
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: AppStyles.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppStyles.borderColor),
          ),
          child: Center(child: Text(notif.emoji,
              style: const TextStyle(fontSize: 18))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(notif.message, style: const TextStyle(color: AppStyles.textMain,
              fontWeight: FontWeight.w600, fontSize: 13)),
          if ((notif.postPreview ?? '').isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(notif.postPreview!, style: const TextStyle(
                color: AppStyles.textMuted, fontSize: 12),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 4),
          Text(_timeAgo(notif.createdAt),
              style: const TextStyle(color: AppStyles.textMuted, fontSize: 11)),
        ])),
        if (!notif.isRead)
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(
              color: AppStyles.accentRed, shape: BoxShape.circle),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CREATION FEED CARD — public creations in feed
// ─────────────────────────────────────────────────────────────────────────────
class _CreationFeedCard extends StatelessWidget {
  final CreationModel creation;
  const _CreationFeedCard({required this.creation});

  Color get _color => switch (creation.type) {
    'journal'    => const Color(0xFF3671C6),
    'prediction' => const Color(0xFFFF8000),
    'collection' => const Color(0xFF229971),
    _            => AppStyles.accentRed,
  };

  String get _emoji => switch (creation.type) {
    'journal'    => '📓',
    'prediction' => '🔮',
    'collection' => '📁',
    _            => '📝',
  };

  String get _typeLabel => switch (creation.type) {
    'journal'    => 'Race Journal',
    'prediction' => 'Prediction Poll',
    'collection' => 'Collection',
    _            => 'Note',
  };

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = creation.mediaUrl != null && creation.mediaUrl!.isNotEmpty;
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => CreationDetailScreen(creation: creation))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppStyles.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _color.withOpacity(0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Author row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(children: [
              _Avatar(username: creation.authorUsername, size: 40, color: _color),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(creation.authorUsername, style: const TextStyle(
                    color: AppStyles.textMain, fontWeight: FontWeight.w800, fontSize: 14)),
                Text(creation.authorHandle, style: const TextStyle(
                    color: AppStyles.textSub, fontSize: 12)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _color.withOpacity(0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(_emoji, style: const TextStyle(fontSize: 10)),
                  const SizedBox(width: 4),
                  Text(_typeLabel, style: TextStyle(color: _color,
                      fontSize: 10, fontWeight: FontWeight.w800)),
                ]),
              ),
            ]),
          ),

          if (hasPhoto)
            Image.network(creation.mediaUrl!, width: double.infinity,
                height: 200, fit: BoxFit.cover),

          Padding(
            padding: EdgeInsets.fromLTRB(14, hasPhoto ? 12 : 0, 14, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(creation.title, style: const TextStyle(color: AppStyles.textMain,
                  fontWeight: FontWeight.w800, fontSize: 15)),
              if (creation.content.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(creation.content, style: AppStyles.bodyText,
                    maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
              if (creation.type == 'prediction' && creation.pollOptions.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...creation.pollOptions.take(2).map((o) {
                  final total = creation.totalVotes;
                  final votes = (o['votes'] as int?) ?? 0;
                  final pct = total > 0 ? votes / total : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppStyles.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _color.withOpacity(0.2)),
                      ),
                      child: Row(children: [
                        Expanded(child: Text(o['label'] as String,
                            style: const TextStyle(color: AppStyles.textMain,
                                fontSize: 12, fontWeight: FontWeight.w600))),
                        if (total > 0)
                          Text('${(pct * 100).round()}%',
                              style: TextStyle(color: _color, fontSize: 12,
                                  fontWeight: FontWeight.w800)),
                      ]),
                    ),
                  );
                }),
              ],
              if (creation.type == 'journal' &&
                  (creation.metadata['circuit'] ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _color.withOpacity(0.2)),
                  ),
                  child: Text('🏁 ${creation.metadata['circuit']}',
                      style: TextStyle(color: _color,
                          fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ]),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(children: [
              const Icon(Icons.public_rounded, color: AppStyles.textMuted, size: 12),
              const SizedBox(width: 4),
              Text(_timeAgo(creation.createdAt),
                  style: const TextStyle(color: AppStyles.textMuted, fontSize: 11)),
              const Spacer(),
              Text('Tap to view', style: TextStyle(color: _color,
                  fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, color: _color, size: 13),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String username;
  final double size;
  final Color? color;
  const _Avatar({required this.username, required this.size, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppStyles.accentRed;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.withOpacity(0.15),
        border: Border.all(color: c.withOpacity(0.4)),
      ),
      child: Center(child: Text(
        username.isNotEmpty ? username[0].toUpperCase() : '?',
        style: TextStyle(color: c, fontWeight: FontWeight.w900,
            fontSize: size * 0.38),
      )),
    );
  }
}

// ── Web scroll fix ────────────────────────────────────────────────────────────
class _WebScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad,
  };
}