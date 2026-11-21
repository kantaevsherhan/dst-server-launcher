import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A short drift on entry and a fresh breeze when the pointer returns.
class WoodlandAtmosphere extends StatefulWidget {
  const WoodlandAtmosphere({super.key});

  @override
  State<WoodlandAtmosphere> createState() => _WoodlandAtmosphereState();
}

class _WoodlandAtmosphereState extends State<WoodlandAtmosphere>
    with SingleTickerProviderStateMixin {
  late final breeze = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );
  bool enabled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate =
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (animate == enabled) return;
    enabled = animate;
    if (animate) {
      breeze.forward(from: 0);
    } else {
      breeze.stop();
      breeze.value = 0;
    }
  }

  @override
  void dispose() {
    breeze.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) {
      if (enabled && !breeze.isAnimating) breeze.forward(from: 0);
    },
    child: RepaintBoundary(child: CustomPaint(painter: _ForestLight(breeze))),
  );
}

class _ForestLight extends CustomPainter {
  _ForestLight(this.breeze) : super(repaint: breeze);
  final Animation<double> breeze;

  @override
  void paint(Canvas canvas, Size size) {
    final t = breeze.value;
    if (t <= 0 || t >= 1) return;
    final envelope = math.sin(math.pi * t);
    final mist = Rect.fromCenter(
      center: Offset(size.width * (.37 + .06 * t), size.height * .61),
      width: size.width * .53,
      height: size.height * .12,
    );
    canvas.drawOval(
      mist,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xffe6e8d7).withValues(alpha: .14 * envelope),
            const Color(0x00e6e8d7),
          ],
        ).createShader(mist),
    );
    for (final (x, y, phase) in const [
      (.20, .74, .2),
      (.33, .80, 1.9),
      (.68, .73, 3.1),
      (.78, .66, 4.2),
    ]) {
      final glow = envelope * (.68 + .32 * math.sin(t * 6 + phase));
      final center = Offset(
        size.width * x + 8 * t,
        size.height * y - 7 * t + 2 * math.sin(t * 4 + phase),
      );
      canvas.drawCircle(
        center,
        3.8,
        Paint()..color = const Color(0xffead494).withValues(alpha: .18 * glow),
      );
      canvas.drawCircle(
        center,
        1.6,
        Paint()..color = const Color(0xffffedb0).withValues(alpha: .86 * glow),
      );
    }
  }

  @override
  bool shouldRepaint(_ForestLight old) => old.breeze != breeze;
}
