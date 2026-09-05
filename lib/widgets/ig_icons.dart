import 'package:flutter/material.dart';

/// Iconos de trazo fino, proporciones cercanas a Instagram.
class IgIcon extends StatelessWidget {
  const IgIcon(this.painter, {super.key, this.size = 24, this.color = Colors.black});

  final CustomPainter painter;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _Tint(painter, color),
    );
  }
}

class _Tint extends CustomPainter {
  _Tint(this.inner, this.color);
  final CustomPainter inner;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    inner.paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _Tint old) =>
      old.color != color || old.inner != inner;
}

Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..isAntiAlias = true;

Paint _fill(Color c) => Paint()
  ..color = c
  ..style = PaintingStyle.fill
  ..isAntiAlias = true;

class HomeOutlinePainter extends CustomPainter {
  HomeOutlinePainter(this.color, {this.filled = false});
  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final path = Path()
      ..moveTo(s * 0.12, s * 0.46)
      ..lineTo(s * 0.50, s * 0.14)
      ..lineTo(s * 0.88, s * 0.46)
      ..lineTo(s * 0.88, s * 0.88)
      ..lineTo(s * 0.58, s * 0.88)
      ..lineTo(s * 0.58, s * 0.62)
      ..lineTo(s * 0.42, s * 0.62)
      ..lineTo(s * 0.42, s * 0.88)
      ..lineTo(s * 0.12, s * 0.88)
      ..close();
    if (filled) {
      canvas.drawPath(path, _fill(color));
    } else {
      canvas.drawPath(path, _stroke(color, s * 0.075));
    }
  }

  @override
  bool shouldRepaint(covariant HomeOutlinePainter old) =>
      old.color != color || old.filled != filled;
}

class SearchOutlinePainter extends CustomPainter {
  SearchOutlinePainter(this.color, {this.bold = false});
  final Color color;
  final bool bold;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final w = bold ? s * 0.095 : s * 0.075;
    canvas.drawCircle(Offset(s * 0.44, s * 0.44), s * 0.30, _stroke(color, w));
    canvas.drawLine(
      Offset(s * 0.66, s * 0.66),
      Offset(s * 0.88, s * 0.88),
      _stroke(color, w),
    );
  }

  @override
  bool shouldRepaint(covariant SearchOutlinePainter old) =>
      old.color != color || old.bold != bold;
}

class AddBoxPainter extends CustomPainter {
  AddBoxPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final r = RRect.fromLTRBR(
      s * 0.10,
      s * 0.10,
      s * 0.90,
      s * 0.90,
      Radius.circular(s * 0.16),
    );
    canvas.drawRRect(r, _stroke(color, s * 0.075));
    canvas.drawLine(Offset(s * 0.50, s * 0.30), Offset(s * 0.50, s * 0.70), _stroke(color, s * 0.075));
    canvas.drawLine(Offset(s * 0.30, s * 0.50), Offset(s * 0.70, s * 0.50), _stroke(color, s * 0.075));
  }

  @override
  bool shouldRepaint(covariant AddBoxPainter old) => old.color != color;
}

class HeartPainter extends CustomPainter {
  HeartPainter(this.color, {this.filled = false});
  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final path = Path()
      ..moveTo(s * 0.50, s * 0.86)
      ..cubicTo(s * 0.20, s * 0.68, s * 0.06, s * 0.50, s * 0.06, s * 0.34)
      ..cubicTo(s * 0.06, s * 0.18, s * 0.20, s * 0.10, s * 0.34, s * 0.16)
      ..cubicTo(s * 0.42, s * 0.20, s * 0.47, s * 0.28, s * 0.50, s * 0.34)
      ..cubicTo(s * 0.53, s * 0.28, s * 0.58, s * 0.20, s * 0.66, s * 0.16)
      ..cubicTo(s * 0.80, s * 0.10, s * 0.94, s * 0.18, s * 0.94, s * 0.34)
      ..cubicTo(s * 0.94, s * 0.50, s * 0.80, s * 0.68, s * 0.50, s * 0.86)
      ..close();
    if (filled) {
      canvas.drawPath(path, _fill(color));
    } else {
      canvas.drawPath(path, _stroke(color, s * 0.075));
    }
  }

  @override
  bool shouldRepaint(covariant HeartPainter old) =>
      old.color != color || old.filled != filled;
}

class CommentPainter extends CustomPainter {
  CommentPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final r = RRect.fromLTRBR(
      s * 0.10,
      s * 0.10,
      s * 0.90,
      s * 0.72,
      Radius.circular(s * 0.28),
    );
    final path = Path()
      ..addRRect(r)
      ..moveTo(s * 0.28, s * 0.70)
      ..quadraticBezierTo(s * 0.24, s * 0.88, s * 0.12, s * 0.90)
      ..quadraticBezierTo(s * 0.32, s * 0.84, s * 0.40, s * 0.72);
    canvas.drawPath(path, _stroke(color, s * 0.075));
  }

  @override
  bool shouldRepaint(covariant CommentPainter old) => old.color != color;
}

class SharePainter extends CustomPainter {
  SharePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final path = Path()
      ..moveTo(s * 0.18, s * 0.46)
      ..lineTo(s * 0.86, s * 0.14)
      ..lineTo(s * 0.52, s * 0.86)
      ..lineTo(s * 0.46, s * 0.54)
      ..close();
    canvas.drawPath(path, _stroke(color, s * 0.075));
  }

  @override
  bool shouldRepaint(covariant SharePainter old) => old.color != color;
}

class BookmarkPainter extends CustomPainter {
  BookmarkPainter(this.color, {this.filled = false});
  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final path = Path()
      ..moveTo(s * 0.22, s * 0.10)
      ..lineTo(s * 0.78, s * 0.10)
      ..lineTo(s * 0.78, s * 0.90)
      ..lineTo(s * 0.50, s * 0.72)
      ..lineTo(s * 0.22, s * 0.90)
      ..close();
    if (filled) {
      canvas.drawPath(path, _fill(color));
    } else {
      canvas.drawPath(path, _stroke(color, s * 0.075));
    }
  }

  @override
  bool shouldRepaint(covariant BookmarkPainter old) =>
      old.color != color || old.filled != filled;
}

class MessengerPainter extends CustomPainter {
  MessengerPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final path = Path()
      ..moveTo(s * 0.14, s * 0.86)
      ..lineTo(s * 0.18, s * 0.52)
      ..quadraticBezierTo(s * 0.08, s * 0.18, s * 0.50, s * 0.12)
      ..quadraticBezierTo(s * 0.94, s * 0.18, s * 0.84, s * 0.54)
      ..quadraticBezierTo(s * 0.72, s * 0.84, s * 0.38, s * 0.78)
      ..close();
    canvas.drawPath(path, _stroke(color, s * 0.075));
    canvas.drawLine(Offset(s * 0.34, s * 0.50), Offset(s * 0.50, s * 0.60), _stroke(color, s * 0.06));
    canvas.drawLine(Offset(s * 0.50, s * 0.60), Offset(s * 0.68, s * 0.42), _stroke(color, s * 0.06));
  }

  @override
  bool shouldRepaint(covariant MessengerPainter old) => old.color != color;
}

class MorePainter extends CustomPainter {
  MorePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    for (final x in [0.22, 0.50, 0.78]) {
      canvas.drawCircle(Offset(s * x, s * 0.50), s * 0.07, _fill(color));
    }
  }

  @override
  bool shouldRepaint(covariant MorePainter old) => old.color != color;
}

class GridPainter extends CustomPainter {
  GridPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final w = s * 0.07;
    for (final x in [0.12, 0.40, 0.68]) {
      for (final y in [0.12, 0.40, 0.68]) {
        canvas.drawRRect(
          RRect.fromLTRBR(s * x, s * y, s * x + s * 0.20, s * y + s * 0.20, Radius.circular(s * 0.03)),
          _stroke(color, w),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter old) => old.color != color;
}

class TagPainter extends CustomPainter {
  TagPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    canvas.drawCircle(Offset(s * 0.50, s * 0.42), s * 0.22, _stroke(color, s * 0.07));
    canvas.drawCircle(Offset(s * 0.50, s * 0.42), s * 0.08, _fill(color));
    canvas.drawArc(
      Rect.fromCircle(center: Offset(s * 0.50, s * 0.98), radius: s * 0.34),
      3.6,
      2.2,
      false,
      _stroke(color, s * 0.07),
    );
  }

  @override
  bool shouldRepaint(covariant TagPainter old) => old.color != color;
}

class MenuPainter extends CustomPainter {
  MenuPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    for (final y in [0.28, 0.50, 0.72]) {
      canvas.drawLine(Offset(s * 0.16, s * y), Offset(s * 0.84, s * y), _stroke(color, s * 0.07));
    }
  }

  @override
  bool shouldRepaint(covariant MenuPainter old) => old.color != color;
}

class BackPainter extends CustomPainter {
  BackPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final path = Path()
      ..moveTo(s * 0.58, s * 0.18)
      ..lineTo(s * 0.22, s * 0.50)
      ..lineTo(s * 0.58, s * 0.82);
    canvas.drawPath(path, _stroke(color, s * 0.08));
  }

  @override
  bool shouldRepaint(covariant BackPainter old) => old.color != color;
}

Widget igIcon(CustomPainter Function(Color) painter,
    {double size = 24, Color color = Colors.black}) {
  return CustomPaint(size: Size.square(size), painter: painter(color));
}
