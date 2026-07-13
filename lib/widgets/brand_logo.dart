import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BrandLogo extends StatelessWidget {
  final double fontSize;
  const BrandLogo({super.key, this.fontSize = 24});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // "ShehrYar" with the two arcs right beneath it
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
                children: const [
                  TextSpan(
                    text: 'Shehr',
                    style: TextStyle(color: Color(0xFF1A1A1A)),
                  ),
                  TextSpan(
                    text: 'Yar',
                    style: TextStyle(color: Color(0xFFD32F2F)),
                  ),
                ],
              ),
            ),
            // ── Double arc immediately under "ShehrYar" ──────────────
            SizedBox(
              width: fontSize * 3.2,  // narrower than the text width
              height: fontSize * 0.32, // thin strip
              child: CustomPaint(painter: _DoubleArcPainter()),
            ),
          ],
        ),
        const SizedBox(height: 1),
        Text(
          'FLEX PRINTER',
          style: GoogleFonts.inter(
            fontSize: fontSize * 0.48,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFD32F2F),
            letterSpacing: 1.8,
          ),
        ),
        if (fontSize >= 20) ...[
          const SizedBox(height: 1),
          Text(
            'Your Design, Our Precision!',
            style: GoogleFonts.pacifico(
              fontSize: fontSize * 0.36,
              color: const Color(0xFFD32F2F),
            ),
          ),
        ],
      ],
    );
  }
}

/// Draws two thin arcs (smile shape) — outer arc = black, inner arc = red.
class _DoubleArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Outer arc — black, very thin
    final blackPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round;

    final outerRect = Rect.fromLTWH(0, 0, w, h * 3.2);
    canvas.drawArc(outerRect, math.pi * 0.04, math.pi * 0.92, false, blackPaint);

    // Inner arc — red, even thinner
    final redPaint = Paint()
      ..color = const Color(0xFFD32F2F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..strokeCap = StrokeCap.round;

    final innerRect = Rect.fromLTWH(w * 0.07, h * 0.55, w * 0.86, h * 2.4);
    canvas.drawArc(innerRect, math.pi * 0.04, math.pi * 0.92, false, redPaint);
  }

  @override
  bool shouldRepaint(_DoubleArcPainter old) => false;
}
