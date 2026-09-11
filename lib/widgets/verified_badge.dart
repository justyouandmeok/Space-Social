import 'package:flutter/material.dart';

/// Tilde oficial Instagram / Meta Verified 2026.
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.size = 14});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 3),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _IgVerifiedPainter()),
      ),
    );
  }
}

class _IgVerifiedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = Offset(s / 2, s / 2);
    canvas.drawCircle(c, s / 2, Paint()..color = const Color(0xFF0095F6));
    final p = Path()
      ..moveTo(s * 0.22, s * 0.50)
      ..lineTo(s * 0.42, s * 0.70)
      ..lineTo(s * 0.78, s * 0.32);
    canvas.drawPath(
      p,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.13
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
