import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Keeps the painted edge and the transparent cutout aligned at any size.
class InkFrame extends StatelessWidget {
  const InkFrame({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipPath(
    clipper: const InkFrameClipper(),
    child: CustomPaint(foregroundPainter: const _InkEdges(), child: child),
  );
}

class InkFrameClipper extends CustomClipper<Path> {
  const InkFrameClipper();

  @override
  Path getClip(Size size) {
    final w = size.width, h = size.height;
    final c = math.min(w / 16, h * .13);
    return Path()
      ..moveTo(0, c * 1.5)
      ..lineTo(c * .48, c * .84)
      ..lineTo(c * .45, c * .57)
      ..lineTo(c * 1.32, 0)
      ..lineTo(w * .28, c * .08)
      ..lineTo(w * .51, c * .025)
      ..lineTo(w * .76, c * .09)
      ..lineTo(w - c * 1.6, 0)
      ..lineTo(w - c * .62, c * .46)
      ..lineTo(w - c * .64, c * .71)
      ..lineTo(w, c * 1.24)
      ..lineTo(w - c * .10, h * .42)
      ..lineTo(w, h - c * 1.46)
      ..lineTo(w - c * .44, h - c * .92)
      ..lineTo(w - c * .42, h - c * .63)
      ..lineTo(w - c * 1.44, h)
      ..lineTo(w * .68, h - c * .09)
      ..lineTo(w * .46, h - c * .025)
      ..lineTo(w * .25, h - c * .08)
      ..lineTo(c * 1.25, h)
      ..lineTo(c * .55, h - c * .49)
      ..lineTo(c * .58, h - c * .71)
      ..lineTo(0, h - c * 1.21)
      ..lineTo(c * .09, h * .58)
      ..close();
  }

  @override
  bool shouldReclip(InkFrameClipper old) => false;
}

class _InkEdges extends CustomPainter {
  const _InkEdges();

  @override
  void paint(Canvas canvas, Size size) {
    final edge = const InkFrameClipper().getClip(size);
    final unit = math.min(size.width / 16, size.height * .13);
    final ink = Paint()..color = const Color(0xff25262a);
    canvas.drawPath(
      edge,
      Paint()
        ..color = ink.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = (unit * .16).clamp(2, 9).toDouble()
        ..strokeJoin = StrokeJoin.bevel,
    );

    // A hooked twig grows in from each corner. Work in corner-local coordinates.
    final twig = Path()
      ..moveTo(.27, .96)
      ..lineTo(.65, .51)
      ..lineTo(1.13, .26)
      ..lineTo(1.72, .34)
      ..lineTo(1.87, .58)
      ..lineTo(1.72, .75)
      ..lineTo(1.55, .66)
      ..lineTo(1.59, .52)
      ..lineTo(1.68, .63)
      ..lineTo(1.72, .56)
      ..lineTo(1.62, .45)
      ..lineTo(1.16, .41)
      ..lineTo(.86, .57)
      ..lineTo(1.04, .82)
      ..lineTo(1.02, 1.07)
      ..lineTo(.92, .83)
      ..lineTo(.74, .69)
      ..close();
    for (final (x, y, sx, sy) in [
      (0.0, 0.0, 1.0, 1.0),
      (size.width, 0.0, -1.0, 1.0),
      (0.0, size.height, 1.0, -1.0),
      (size.width, size.height, -1.0, -1.0),
    ]) {
      canvas.save();
      canvas.translate(x, y);
      canvas.scale(unit * sx, unit * sy);
      canvas.drawPath(twig, ink);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_InkEdges old) => false;
}
