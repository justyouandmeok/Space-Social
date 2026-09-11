import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Tilde Instagram 2026: sello festoneado #0095F6 + check blanco.
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
    const points = 12;
    final outer = s / 2;
    final inner = s / 2 * 0.78;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + (i * math.pi / points);
      final p = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF0095F6));

    final check = Path()
      ..moveTo(s * 0.26, s * 0.50)
      ..lineTo(s * 0.43, s * 0.66)
      ..lineTo(s * 0.74, s * 0.34);
    canvas.drawPath(
      check,
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
