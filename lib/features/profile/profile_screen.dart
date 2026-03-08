import 'package:flutter/material.dart';
import 'package:formulandsocialapp/core/app_styles.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.background,
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
                  const Text(
                    "Alex Hamilton",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppStyles.textMain,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "@strategy_fan_44",
                    style: TextStyle(color: AppStyles.textSub, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Racing fan since birth. Strategy nerd. Tifosi at heart but I'll acknowledge a dominant performance when I see one.",
                    style: AppStyles.bodyText,
                  ),
                  const SizedBox(height: 20),
                  _buildStatRow(),
                  const SizedBox(height: 24),
                  _buildActionRow(),
                  const SizedBox(height: 28),
                  Text("GRID", style: AppStyles.label),
                  const SizedBox(height: 14),
                  _buildCreationsGrid(),
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
              // Racing stripes
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: CustomPaint(painter: _RaceStripePainter()),
              ),
              Positioned(
                top: 50,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                border: Border.all(color: AppStyles.accentRed.withOpacity(0.5), width: 2),
              ),
              child: const Center(
                child: Text(
                  "AH",
                  style: TextStyle(
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

  Widget _buildStatRow() {
    return Row(
      children: [
        _ProfileStat(label: "Race Logs", value: "24"),
        Container(
          width: 1,
          height: 30,
          color: AppStyles.borderColor,
          margin: const EdgeInsets.symmetric(horizontal: 24),
        ),
        _ProfileStat(label: "Followers", value: "1.2k"),
        Container(
          width: 1,
          height: 30,
          color: AppStyles.borderColor,
          margin: const EdgeInsets.symmetric(horizontal: 24),
        ),
        _ProfileStat(label: "Following", value: "318"),
      ],
    );
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
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
        const SizedBox(width: 10),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppStyles.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppStyles.borderColor),
          ),
          child: const Icon(Icons.share_outlined, color: AppStyles.textSub, size: 18),
        ),
        const SizedBox(width: 8),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppStyles.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppStyles.borderColor),
          ),
          child: const Icon(Icons.more_horiz, color: AppStyles.textSub, size: 18),
        ),
      ],
    );
  }

  Widget _buildCreationsGrid() {
    final accentColors = [
      AppStyles.accentRed.withOpacity(0.15),
      Colors.transparent,
      Colors.transparent,
      AppStyles.accentRed.withOpacity(0.08),
      Colors.transparent,
      Colors.transparent,
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 12,
      itemBuilder: (context, i) => Container(
        decoration: BoxDecoration(
          color: AppStyles.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: i % 5 == 0 ? AppStyles.accentRed.withOpacity(0.3) : AppStyles.borderColor,
          ),
          gradient: i % 5 == 0
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A0000), Color(0xFF141414)],
                )
              : null,
        ),
      ),
    );
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