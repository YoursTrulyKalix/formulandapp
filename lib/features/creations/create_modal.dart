// lib/features/creations/create_modal.dart

import 'package:flutter/material.dart';
import 'package:formulandsocialapp/core/app_styles.dart';
import 'package:formulandsocialapp/core/data/f1_data.dart';
import 'package:formulandsocialapp/core/services/creation_service.dart';

void showCreateModal(BuildContext context, {VoidCallback? onCreated}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _TypePickerSheet(onCreated: onCreated),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TYPE PICKER SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _TypePickerSheet extends StatelessWidget {
  final VoidCallback? onCreated;
  const _TypePickerSheet({this.onCreated});

  static const _types = [
    {'type': 'note',       'emoji': '📝', 'label': 'Note',        'sub': 'A quick thought or observation',                       'color': 0xFFE10600},
    {'type': 'journal',    'emoji': '📓', 'label': 'Race Journal', 'sub': 'Full diary entry for a GP weekend',                   'color': 0xFF3671C6},
    {'type': 'prediction', 'emoji': '🔮', 'label': 'Prediction',   'sub': 'Pick pole, podium & winner — others can vote',        'color': 0xFFFF8000},
    {'type': 'collection', 'emoji': '📁', 'label': 'Collection',   'sub': 'Curate your favourite moments & overtakes',           'color': 0xFF229971},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(color: AppStyles.borderColor, borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 20),
          Text('What are you creating?', style: AppStyles.headingL),
          const SizedBox(height: 4),
          const Text('Choose a format for your Garage', style: AppStyles.bodyText),
          const SizedBox(height: 20),
          ..._types.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TypeTile(
              emoji: t['emoji'] as String,
              label: t['label'] as String,
              subtitle: t['sub'] as String,
              color: Color(t['color'] as int),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => _CreateFormSheet(
                    type: t['type'] as String,
                    color: Color(t['color'] as int),
                    onCreated: onCreated,
                  ),
                );
              },
            ),
          )),
        ],
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  final String emoji, label, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _TypeTile({required this.emoji, required this.label,
      required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppStyles.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppStyles.borderColor),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppStyles.textMain, fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: AppStyles.textSub, fontSize: 12)),
            ],
          )),
          Icon(Icons.chevron_right_rounded, color: color, size: 20),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CREATE FORM SHEET — adapts per type
// ─────────────────────────────────────────────────────────────────────────────
class _CreateFormSheet extends StatefulWidget {
  final String type;
  final Color color;
  final VoidCallback? onCreated;
  const _CreateFormSheet({required this.type, required this.color, this.onCreated});

  @override
  State<_CreateFormSheet> createState() => _CreateFormSheetState();
}

class _CreateFormSheetState extends State<_CreateFormSheet> {
  bool _isPublic = false;
  bool _saving = false;

  // ── Shared
  final _titleCtrl = TextEditingController();

  // ── Note
  final _noteCtrl = TextEditingController();

  // ── Journal
  final _circuitCtrl = TextEditingController();
  final _p1Ctrl = TextEditingController();      // Q session
  final _raceWinnerCtrl = TextEditingController();
  final _fl1Ctrl = TextEditingController();     // Friday lap 1
  final _saturdayCtrl = TextEditingController();
  final _raceCtrl = TextEditingController();
  final _momentCtrl = TextEditingController();
  final _verdictCtrl = TextEditingController();
  String? _myResult;

  // ── Prediction (poll)
  final _poleCtrl = TextEditingController();
  final _winnerCtrl = TextEditingController();
  final List<TextEditingController> _podiumCtrls = [
    TextEditingController(), TextEditingController(), TextEditingController(),
  ];
  final _predReasonCtrl = TextEditingController();

  // ── Collection
  final _collDescCtrl = TextEditingController();
  final _collThemeCtrl = TextEditingController();

  List<String> get _codes => F1DataService.drivers.map((d) => d.code).toList();

  String get _typeLabel => switch (widget.type) {
    'journal'    => 'Race Journal',
    'prediction' => 'Prediction Poll',
    'collection' => 'Collection',
    _            => 'Note',
  };

  String get _typeEmoji => switch (widget.type) {
    'journal'    => '📓',
    'prediction' => '🔮',
    'collection' => '📁',
    _            => '📝',
  };

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);

    try {
      String content = '';
      Map<String, dynamic> metadata = {};
      List<Map<String, dynamic>> pollOptions = [];

      switch (widget.type) {
        case 'note':
          content = _noteCtrl.text.trim();

        case 'journal':
          metadata = {
            'circuit':     _circuitCtrl.text.trim(),
            'myResult':    _myResult ?? '',
            'qualiPole':   _p1Ctrl.text.trim(),
            'raceWinner':  _raceWinnerCtrl.text.trim(),
            'friday':      _fl1Ctrl.text.trim(),
            'saturday':    _saturdayCtrl.text.trim(),
            'race':        _raceCtrl.text.trim(),
            'standoutMoment': _momentCtrl.text.trim(),
            'verdict':     _verdictCtrl.text.trim(),
          };

        case 'prediction':
          // Poll options: Pole, P1, P2, P3 — each as a driver pick option
          // Others vote by picking their own answers
          pollOptions = [
            {'label': 'Pole: ${_poleCtrl.text.trim().isEmpty ? '?' : _poleCtrl.text.trim()}', 'votes': 0},
            {'label': 'Winner: ${_winnerCtrl.text.trim().isEmpty ? '?' : _winnerCtrl.text.trim()}', 'votes': 0},
            {'label': 'P2: ${_podiumCtrls[1].text.trim().isEmpty ? '?' : _podiumCtrls[1].text.trim()}', 'votes': 0},
            {'label': 'P3: ${_podiumCtrls[2].text.trim().isEmpty ? '?' : _podiumCtrls[2].text.trim()}', 'votes': 0},
          ];
          metadata = {
            'pole':    _poleCtrl.text.trim(),
            'winner':  _winnerCtrl.text.trim(),
            'p2':      _podiumCtrls[1].text.trim(),
            'p3':      _podiumCtrls[2].text.trim(),
            'reasoning': _predReasonCtrl.text.trim(),
          };
          content = _predReasonCtrl.text.trim();

        case 'collection':
          metadata = {
            'theme':       _collThemeCtrl.text.trim(),
            'description': _collDescCtrl.text.trim(),
            'itemCount':   0,
          };
          content = _collDescCtrl.text.trim();
      }

      await CreationService.instance.createCreation(
        type: widget.type,
        title: _titleCtrl.text.trim(),
        content: content,
        metadata: metadata,
        isPublic: _isPublic,
        pollOptions: pollOptions,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onCreated?.call();
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final c in [_titleCtrl, _noteCtrl, _circuitCtrl, _p1Ctrl,
        _raceWinnerCtrl, _fl1Ctrl, _saturdayCtrl, _raceCtrl,
        _momentCtrl, _verdictCtrl, _poleCtrl, _winnerCtrl,
        _predReasonCtrl, _collDescCtrl, _collThemeCtrl, ..._podiumCtrls]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: AppStyles.borderColor, borderRadius: BorderRadius.circular(2)),
              )),
              const SizedBox(height: 16),

              // Top bar
              Row(children: [
                Text(_typeEmoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(_typeLabel, style: AppStyles.headingL),
                const Spacer(),
                _SaveBtn(saving: _saving, color: widget.color, onTap: _save),
              ]),
              const SizedBox(height: 18),

              // Public toggle
              _PublicToggle(
                isPublic: _isPublic,
                color: widget.color,
                onChanged: (v) => setState(() => _isPublic = v),
              ),
              const SizedBox(height: 18),

              // Title
              _field(_titleCtrl, 'Title', maxLines: 1),
              const SizedBox(height: 14),

              // Type-specific fields
              if (widget.type == 'note')       _NoteFields(ctrl: _noteCtrl, color: widget.color),
              if (widget.type == 'journal')    _JournalFields(
                circuitCtrl: _circuitCtrl,
                p1Ctrl: _p1Ctrl,
                raceWinnerCtrl: _raceWinnerCtrl,
                fridayCtrl: _fl1Ctrl,
                saturdayCtrl: _saturdayCtrl,
                raceCtrl: _raceCtrl,
                momentCtrl: _momentCtrl,
                verdictCtrl: _verdictCtrl,
                myResult: _myResult,
                onResultChanged: (v) => setState(() => _myResult = v),
                color: widget.color,
                driverCodes: _codes,
              ),
              if (widget.type == 'prediction') _PredictionFields(
                poleCtrl: _poleCtrl,
                winnerCtrl: _winnerCtrl,
                podiumCtrls: _podiumCtrls,
                reasonCtrl: _predReasonCtrl,
                color: widget.color,
                driverCodes: _codes,
              ),
              if (widget.type == 'collection') _CollectionFields(
                themeCtrl: _collThemeCtrl,
                descCtrl: _collDescCtrl,
                color: widget.color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: AppStyles.textMain, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppStyles.textMuted),
        filled: true, fillColor: AppStyles.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppStyles.borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppStyles.borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: widget.color)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTE FIELDS
// ─────────────────────────────────────────────────────────────────────────────
class _NoteFields extends StatelessWidget {
  final TextEditingController ctrl;
  final Color color;
  const _NoteFields({required this.ctrl, required this.color});

  @override
  Widget build(BuildContext context) {
    return _FormField(ctrl: ctrl, hint: 'Write your thought or observation…', maxLines: 8, color: color);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// JOURNAL FIELDS — full GP weekend diary
// ─────────────────────────────────────────────────────────────────────────────
class _JournalFields extends StatelessWidget {
  final TextEditingController circuitCtrl, p1Ctrl, raceWinnerCtrl,
      fridayCtrl, saturdayCtrl, raceCtrl, momentCtrl, verdictCtrl;
  final String? myResult;
  final ValueChanged<String?> onResultChanged;
  final Color color;
  final List<String> driverCodes;

  const _JournalFields({
    required this.circuitCtrl, required this.p1Ctrl, required this.raceWinnerCtrl,
    required this.fridayCtrl, required this.saturdayCtrl, required this.raceCtrl,
    required this.momentCtrl, required this.verdictCtrl,
    required this.myResult, required this.onResultChanged,
    required this.color, required this.driverCodes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _FormField(ctrl: circuitCtrl, hint: 'Circuit / Grand Prix name', maxLines: 1, color: color),
      const SizedBox(height: 16),

      _SectionHeader(emoji: '🏁', label: 'RACE RESULT', color: color),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _DriverDropdown(label: '🥇 Pole', value: p1Ctrl.text.isEmpty ? null : p1Ctrl.text,
            codes: driverCodes, color: color,
            onChanged: (v) => p1Ctrl.text = v ?? '')),
        const SizedBox(width: 10),
        Expanded(child: _DriverDropdown(label: '🏆 Winner', value: raceWinnerCtrl.text.isEmpty ? null : raceWinnerCtrl.text,
            codes: driverCodes, color: color,
            onChanged: (v) => raceWinnerCtrl.text = v ?? '')),
      ]),
      const SizedBox(height: 16),

      _SectionHeader(emoji: '📅', label: 'WEEKEND DIARY', color: color),
      const SizedBox(height: 10),
      _FormField(ctrl: fridayCtrl, hint: '🗓️ Friday — Practice sessions, first impressions…', maxLines: 4, color: color),
      const SizedBox(height: 12),
      _FormField(ctrl: saturdayCtrl, hint: '⚡ Saturday — Qualifying, drama, who shone…', maxLines: 4, color: color),
      const SizedBox(height: 12),
      _FormField(ctrl: raceCtrl, hint: '🏎️ Race day — lap 1, strategy battles, key moments…', maxLines: 5, color: color),
      const SizedBox(height: 16),

      _SectionHeader(emoji: '💥', label: 'HIGHLIGHTS', color: color),
      const SizedBox(height: 10),
      _FormField(ctrl: momentCtrl, hint: 'Standout moment of the weekend…', maxLines: 3, color: color),
      const SizedBox(height: 12),
      _FormField(ctrl: verdictCtrl, hint: '⭐ Your verdict — rate the race weekend…', maxLines: 3, color: color),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PREDICTION FIELDS — poll that others can vote on
// ─────────────────────────────────────────────────────────────────────────────
class _PredictionFields extends StatefulWidget {
  final TextEditingController poleCtrl, winnerCtrl, reasonCtrl;
  final List<TextEditingController> podiumCtrls;
  final Color color;
  final List<String> driverCodes;

  const _PredictionFields({
    required this.poleCtrl, required this.winnerCtrl,
    required this.podiumCtrls, required this.reasonCtrl,
    required this.color, required this.driverCodes,
  });

  @override
  State<_PredictionFields> createState() => _PredictionFieldsState();
}

class _PredictionFieldsState extends State<_PredictionFields> {
  String? _pole, _winner, _p2, _p3;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Info banner
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.color.withOpacity(0.25)),
        ),
        child: Row(children: [
          Icon(Icons.poll_rounded, color: widget.color, size: 16),
          const SizedBox(width: 10),
          const Expanded(child: Text(
            'This will be posted as a public poll. Other fans can agree or disagree with your picks.',
            style: TextStyle(color: AppStyles.textSub, fontSize: 12),
          )),
        ]),
      ),
      const SizedBox(height: 16),

      _SectionHeader(emoji: '⚡', label: 'YOUR PICKS', color: widget.color),
      const SizedBox(height: 10),

      // Pole
      _DriverDropdown(label: '⚡ Pole Position', value: _pole, codes: widget.driverCodes,
          color: widget.color, onChanged: (v) { setState(() => _pole = v); widget.poleCtrl.text = v ?? ''; }),
      const SizedBox(height: 10),

      // Winner
      _DriverDropdown(label: '🏆 Race Winner', value: _winner, codes: widget.driverCodes,
          color: widget.color, onChanged: (v) { setState(() => _winner = v); widget.winnerCtrl.text = v ?? ''; }),
      const SizedBox(height: 10),

      // P2 + P3
      Row(children: [
        Expanded(child: _DriverDropdown(label: '🥈 P2', value: _p2, codes: widget.driverCodes,
            color: widget.color, onChanged: (v) { setState(() => _p2 = v); widget.podiumCtrls[1].text = v ?? ''; })),
        const SizedBox(width: 10),
        Expanded(child: _DriverDropdown(label: '🥉 P3', value: _p3, codes: widget.driverCodes,
            color: widget.color, onChanged: (v) { setState(() => _p3 = v); widget.podiumCtrls[2].text = v ?? ''; })),
      ]),
      const SizedBox(height: 16),

      _SectionHeader(emoji: '💬', label: 'REASONING', color: widget.color),
      const SectionGap(),
      _FormField(ctrl: widget.reasonCtrl, hint: 'Why do you think this? Tyre strategy, grid penalty, weather…', maxLines: 4, color: widget.color),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COLLECTION FIELDS
// ─────────────────────────────────────────────────────────────────────────────
class _CollectionFields extends StatelessWidget {
  final TextEditingController themeCtrl, descCtrl;
  final Color color;
  const _CollectionFields({required this.themeCtrl, required this.descCtrl, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _FormField(ctrl: themeCtrl, hint: 'Theme (e.g. Best Overtakes 2026, Crazy Lap 1s…)', maxLines: 1, color: color),
      const SizedBox(height: 12),
      _FormField(ctrl: descCtrl, hint: 'Describe what you\'re collecting…', maxLines: 4, color: color),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppStyles.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppStyles.borderColor),
        ),
        child: const Row(children: [
          Icon(Icons.info_outline, color: AppStyles.textMuted, size: 15),
          SizedBox(width: 10),
          Expanded(child: Text('Add posts and moments to this collection after creating it.',
              style: TextStyle(color: AppStyles.textMuted, fontSize: 12))),
        ]),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED HELPER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final int maxLines;
  final Color color;
  const _FormField({required this.ctrl, required this.hint, required this.maxLines, required this.color});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: AppStyles.textMain, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppStyles.textMuted, fontSize: 13),
        filled: true, fillColor: AppStyles.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppStyles.borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppStyles.borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: color)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String emoji, label;
  final Color color;
  const _SectionHeader({required this.emoji, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 14)),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
    ]);
  }
}

class SectionGap extends StatelessWidget {
  const SectionGap({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox(height: 10);
}

class _DriverDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> codes;
  final Color color;
  final ValueChanged<String?> onChanged;
  const _DriverDropdown({required this.label, required this.value,
      required this.codes, required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppStyles.textSub, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppStyles.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: value != null ? color.withOpacity(0.4) : AppStyles.borderColor),
          ),
          child: DropdownButton<String>(
            value: value,
            hint: const Text('—', style: TextStyle(color: AppStyles.textMuted)),
            isExpanded: true, underline: const SizedBox(),
            dropdownColor: const Color(0xFF1A1A1A),
            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800),
            items: codes.map((c) => DropdownMenuItem(value: c,
                child: Text(c, style: const TextStyle(color: AppStyles.textMain, fontWeight: FontWeight.w700)))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _SaveBtn extends StatelessWidget {
  final bool saving;
  final Color color;
  final VoidCallback onTap;
  const _SaveBtn({required this.saving, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: saving ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: saving
            ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
      ),
    );
  }
}

class _PublicToggle extends StatelessWidget {
  final bool isPublic;
  final Color color;
  final ValueChanged<bool> onChanged;
  const _PublicToggle({required this.isPublic, required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isPublic),
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
            Text(isPublic ? 'Others can see this in feed & your profile'
                : 'Only visible to you in your Garage',
                style: const TextStyle(color: AppStyles.textMuted, fontSize: 11)),
          ])),
          // Pill toggle
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