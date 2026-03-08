import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:formulandsocialapp/core/app_styles.dart';

class CreatePostModal extends StatelessWidget {
  const CreatePostModal({super.key});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(28, 16, 28, 40),
        decoration: BoxDecoration(
          color: AppStyles.surface.withOpacity(0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: const Border(
            top: BorderSide(color: AppStyles.borderColor, width: 1),
            left: BorderSide(color: AppStyles.borderColor, width: 1),
            right: BorderSide(color: AppStyles.borderColor, width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                color: AppStyles.softGrey,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("NEW POST", style: AppStyles.label),
                    const SizedBox(height: 4),
                    const Text(
                      "Capture the Race",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppStyles.textMain,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: _option(Icons.camera_alt_rounded, "Photo", "Snap the action")),
                const SizedBox(width: 12),
                Expanded(child: _option(Icons.edit_rounded, "Race Log", "Track the race")),
                const SizedBox(width: 12),
                Expanded(child: _option(Icons.poll_rounded, "Poll", "Fan vote")),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppStyles.accentRed, Color(0xFFAA0400)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  "Start Creating",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _option(IconData icon, String label, String sub) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: AppStyles.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppStyles.borderColor),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppStyles.accentRed.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppStyles.accentRed.withOpacity(0.25)),
            ),
            child: Icon(icon, color: AppStyles.accentRed, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppStyles.textMain,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 10,
              color: AppStyles.textSub,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}