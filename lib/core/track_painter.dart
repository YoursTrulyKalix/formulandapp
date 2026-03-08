import 'package:flutter/material.dart';

class TrackBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Red glow streak — top
    final glowPaint = Paint()
      ..color = const Color(0xFFE10600).withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 80
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);

    final topPath = Path()
      ..moveTo(-40, size.height * 0.15)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.0, size.width + 40, size.height * 0.25);

    canvas.drawPath(topPath, glowPaint);

    // Thin sharp red racing line
    final sharpLinePaint = Paint()
      ..color = const Color(0xFFE10600).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final sharpPath = Path()
      ..moveTo(-40, size.height * 0.15)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.0, size.width + 40, size.height * 0.25);

    canvas.drawPath(sharpPath, sharpLinePaint);

    // Bottom glow streak
    final bottomPath = Path()
      ..moveTo(size.width + 40, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.95, -40, size.height * 0.8);

    canvas.drawPath(bottomPath, glowPaint);
    canvas.drawPath(bottomPath, sharpLinePaint);

    // Subtle grid dots — carbon fibre texture suggestion
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.fill;

    const spacing = 32.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..style = PaintingStyle.fill;

    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}