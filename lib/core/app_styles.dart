import 'package:flutter/material.dart';

class AppStyles {
  // Core Palette — F1 Dark Theme
  static const Color background = Color(0xFF0A0A0A);       // Near-black carbon
  static const Color surface = Color(0xFF141414);           // Card surface
  static const Color surfaceElevated = Color(0xFF1E1E1E);  // Elevated surfaces
  static const Color accentRed = Color(0xFFE10600);         // F1 racing red
  static const Color accentRedDim = Color(0xFF8C0400);      // Dimmed red
  static const Color softGrey = Color(0xFF2A2A2A);          // Subtle grey
  static const Color borderColor = Color(0xFF2C2C2C);       // Borders
  static const Color textMain = Color(0xFFF5F5F5);          // Primary text
  static const Color textSub = Color(0xFF888888);           // Secondary text
  static const Color textMuted = Color(0xFF444444);         // Muted text

  static BoxDecoration cardDecoration = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: borderColor, width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.5),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static BoxDecoration heroCardDecoration = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: accentRed.withOpacity(0.3), width: 1),
    boxShadow: [
      BoxShadow(
        color: accentRed.withOpacity(0.08),
        blurRadius: 40,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.6),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // Text Styles
  static const TextStyle headingXL = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w900,
    color: textMain,
    letterSpacing: -1.5,
    height: 1.0,
  );

  static const TextStyle headingL = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: textMain,
    letterSpacing: -0.8,
  );

  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: accentRed,
    letterSpacing: 2.0,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 14,
    color: textSub,
    height: 1.5,
  );
}