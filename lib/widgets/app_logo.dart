import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Logo "Volant" — option 1b retenue dans le handoff design
/// (`design_handoff_logo_renta_vtc`). Reproduit vectoriellement en
/// `CustomPainter` (plutôt qu'une image bitmap) pour rester net à toute
/// taille dans l'app. Les proportions suivent le viewBox 60×60 du handoff :
/// anneau 38px Ø / trait 4px, 3 rayons 3px × 44px à 0°/60°/120°, moyeu
/// 12px Ø + trait 3px.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 26});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _AppLogoPainter()),
    );
  }
}

class _AppLogoPainter extends CustomPainter {
  static const _dark = Color(0xFF1C1D20);
  static const _orange = Color(0xFFF2A33D);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 60;
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(16 * s)),
      Paint()..color = _dark,
    );

    final spokePaint = Paint()
      ..color = _orange
      ..strokeWidth = 3 * s
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    for (final degrees in const [0, 60, 120]) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(degrees * math.pi / 180);
      canvas.drawLine(Offset(0, -22 * s), Offset(0, 22 * s), spokePaint);
      canvas.restore();
    }

    canvas.drawCircle(
      center,
      21 * s,
      Paint()
        ..color = _orange
        ..strokeWidth = 4 * s
        ..style = PaintingStyle.stroke,
    );

    canvas.drawCircle(
      center,
      7.5 * s,
      Paint()
        ..color = _orange
        ..strokeWidth = 3 * s
        ..style = PaintingStyle.stroke,
    );

    canvas.drawCircle(center, 6 * s, Paint()..color = _dark);
  }

  @override
  bool shouldRepaint(covariant _AppLogoPainter oldDelegate) => false;
}
