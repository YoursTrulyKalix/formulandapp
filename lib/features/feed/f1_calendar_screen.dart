// lib/features/feed/f1_calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:formulandsocialapp/core/app_styles.dart';
import 'package:formulandsocialapp/core/data/f1_data.dart';

class F1CalendarScreen extends StatelessWidget {
  const F1CalendarScreen({super.key});

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _countdown(DateTime d) {
    final diff = d.difference(DateTime.now());
    if (diff.isNegative) return 'Completed';
    if (diff.inDays > 0) return '${diff.inDays}d away';
    if (diff.inHours > 0) return '${diff.inHours}h away';
    return '${diff.inMinutes}m away';
  }

  @override
  Widget build(BuildContext context) {
    final races = F1DataService.calendar;
    final now = DateTime.now();
    final nextIndex = races.indexWhere((r) => r.isUpcoming || r.isLive);

    return Scaffold(
      backgroundColor: AppStyles.background,
      appBar: AppBar(
        backgroundColor: AppStyles.background,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppStyles.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppStyles.borderColor),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('2026 SEASON', style: AppStyles.label),
            Text('F1 Calendar', style: AppStyles.headingL),
          ],
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: races.length,
        itemBuilder: (context, i) {
          final race = races[i];
          final isNext = i == nextIndex;
          final isLive = race.isLive;
          final isDone = race.isCompleted;

          Color statusColor = AppStyles.textMuted;
          if (isLive) statusColor = AppStyles.accentRed;
          else if (isNext) statusColor = const Color(0xFFFF8000);
          else if (isDone) statusColor = AppStyles.textMuted;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isLive
                  ? const Color(0xFF1A0000)
                  : isNext
                      ? AppStyles.surface
                      : AppStyles.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLive
                    ? AppStyles.accentRed.withOpacity(0.5)
                    : isNext
                        ? const Color(0xFFFF8000).withOpacity(0.4)
                        : AppStyles.borderColor,
              ),
              boxShadow: isLive
                  ? [BoxShadow(color: AppStyles.accentRed.withOpacity(0.15), blurRadius: 16)]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Round number
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: isDone && !isLive
                          ? AppStyles.softGrey
                          : statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: isDone && !isLive
                          ? const Icon(Icons.check_rounded, color: AppStyles.textMuted, size: 16)
                          : Text('${race.round}',
                              style: TextStyle(color: statusColor,
                                  fontWeight: FontWeight.w900, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Flag + info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(race.flagEmoji, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              race.raceName,
                              style: TextStyle(
                                color: isDone ? AppStyles.textSub : AppStyles.textMain,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 3),
                        Text(race.circuit,
                            style: const TextStyle(color: AppStyles.textMuted, fontSize: 11)),
                        const SizedBox(height: 3),
                        Text(_formatDate(race.raceDate),
                            style: const TextStyle(color: AppStyles.textSub, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),

                  // Status / badges
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Live badge
                      if (isLive)
                        _Badge(label: 'LIVE', color: AppStyles.accentRed, pulse: true),
                      // Next badge
                      if (isNext && !isLive)
                        _Badge(label: 'NEXT', color: const Color(0xFFFF8000)),
                      // Sprint badge
                      if (race.isSprint) ...[
                        const SizedBox(height: 4),
                        _Badge(label: 'SPRINT', color: const Color(0xFFFF8000), outlined: true),
                      ],
                      // Countdown for upcoming
                      if (!isDone && !isLive) ...[
                        const SizedBox(height: 6),
                        Text(_countdown(race.raceDate),
                            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Badge widget ──────────────────────────────────────────────────────────────
class _Badge extends StatefulWidget {
  final String label;
  final Color color;
  final bool pulse;
  final bool outlined;
  const _Badge({required this.label, required this.color,
      this.pulse = false, this.outlined = false});

  @override
  State<_Badge> createState() => _BadgeState();
}

class _BadgeState extends State<_Badge> with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;

  @override
  void initState() {
    super.initState();
    if (widget.pulse) {
      _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() { _ctrl?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (widget.pulse && _ctrl != null) {
      return AnimatedBuilder(
        animation: _ctrl!,
        builder: (_, __) => _chip(_ctrl!.value),
      );
    }
    return _chip(1.0);
  }

  Widget _chip(double opacity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: widget.outlined ? Colors.transparent : widget.color.withOpacity(0.15 + opacity * 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: widget.color.withOpacity(widget.outlined ? 0.4 : 0.5)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (widget.pulse)
          Container(
            width: 5, height: 5,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.5 + opacity * 0.5),
              shape: BoxShape.circle,
            ),
          ),
        Text(widget.label, style: TextStyle(
            color: widget.color, fontSize: 9,
            fontWeight: FontWeight.w900, letterSpacing: 1)),
      ]),
    );
  }
}