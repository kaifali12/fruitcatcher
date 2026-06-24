import 'package:flutter/material.dart';

import '../game/game_constants.dart';

/// A wicker-basket-ish shape drawn from primitives. No image asset required.
class BasketWidget extends StatelessWidget {
  const BasketWidget({super.key});

  @override
  Widget build(BuildContext context) {
    const double w = GameConstants.basketWidth;
    const double h = GameConstants.basketHeight;
    return SizedBox(
      width: w,
      height: h,
      child: CustomPaint(painter: _BasketPainter()),
    );
  }
}

class _BasketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint body = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          GameConstants.basketWood,
          GameConstants.basketWoodDark,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final Paint rim = Paint()
      ..color = const Color(0xFFD89867)
      ..style = PaintingStyle.fill;

    // Body — trapezoid shape narrower at the bottom
    final Path path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.32)
      ..lineTo(size.width * 0.92, size.height * 0.32)
      ..lineTo(size.width * 0.82, size.height)
      ..lineTo(size.width * 0.18, size.height)
      ..close();
    canvas.drawPath(path, body);

    // Weave lines
    final Paint weave = Paint()
      ..color = const Color(0x66442713)
      ..strokeWidth = 1.2;
    for (double y = size.height * 0.45; y < size.height; y += 9) {
      canvas.drawLine(Offset(size.width * 0.13, y),
          Offset(size.width * 0.87, y), weave);
    }
    for (double x = size.width * 0.18; x < size.width * 0.82; x += 12) {
      canvas.drawLine(Offset(x, size.height * 0.34),
          Offset(x, size.height * 0.98), weave);
    }

    final RRect rimRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height * 0.20, size.width, size.height * 0.22),
      const Radius.circular(20),
    );
    canvas.drawRRect(rimRect, rim);

    final Paint hi = Paint()
      ..color = const Color(0x55FFFFFF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromLTWH(size.width * 0.10, size.height * 0.22,
          size.width * 0.80, size.height * 0.18),
      3.6, 1.7, false, hi,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
