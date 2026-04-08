import 'package:flutter/material.dart';

/// Affiche le losange de baseball avec les coureurs sur les buts.
class BaseDiamondWidget extends StatelessWidget {
  final bool runner1st;
  final bool runner2nd;
  final bool runner3rd;
  final int outs;
  final double size;

  const BaseDiamondWidget({
    super.key,
    required this.runner1st,
    required this.runner2nd,
    required this.runner3rd,
    required this.outs,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _DiamondPainter(
              runner1st: runner1st,
              runner2nd: runner2nd,
              runner3rd: runner3rd,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Outs indicator
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Retraits: ',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            for (int i = 0; i < 3; i++)
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < outs ? Colors.redAccent : Colors.transparent,
                  border: Border.all(
                    color: i < outs ? Colors.redAccent : Colors.white38,
                    width: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DiamondPainter extends CustomPainter {
  final bool runner1st;
  final bool runner2nd;
  final bool runner3rd;

  _DiamondPainter({
    required this.runner1st,
    required this.runner2nd,
    required this.runner3rd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final halfBase = size.width * 0.28;

    final bases = {
      'home': Offset(cx, cy + halfBase),
      '1st': Offset(cx + halfBase, cy),
      '2nd': Offset(cx, cy - halfBase),
      '3rd': Offset(cx - halfBase, cy),
    };

    // Draw diamond lines
    final linePaint = Paint()
      ..color = Colors.white30
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(bases['home']!.dx, bases['home']!.dy)
      ..lineTo(bases['1st']!.dx, bases['1st']!.dy)
      ..lineTo(bases['2nd']!.dx, bases['2nd']!.dy)
      ..lineTo(bases['3rd']!.dx, bases['3rd']!.dy)
      ..close();
    canvas.drawPath(path, linePaint);

    // Draw bases
    _drawBase(canvas, bases['home']!, false, isHome: true);
    _drawBase(canvas, bases['1st']!, runner1st);
    _drawBase(canvas, bases['2nd']!, runner2nd);
    _drawBase(canvas, bases['3rd']!, runner3rd);
  }

  void _drawBase(Canvas canvas, Offset center, bool hasRunner,
      {bool isHome = false}) {
    final size = isHome ? 8.0 : 10.0;

    final fillPaint = Paint()
      ..color = hasRunner ? Colors.amber : Colors.white24
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = hasRunner ? Colors.amber : Colors.white54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    if (isHome) {
      // Pentagon for home plate
      final rect =
          Rect.fromCenter(center: center, width: size * 2, height: size * 2);
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, borderPaint);
    } else {
      // Rotated square for bases
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(0.785398); // 45 degrees
      final rect = Rect.fromCenter(
          center: Offset.zero, width: size, height: size);
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, borderPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_DiamondPainter old) =>
      old.runner1st != runner1st ||
      old.runner2nd != runner2nd ||
      old.runner3rd != runner3rd;
}
