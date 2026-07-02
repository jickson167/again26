import 'package:flutter/material.dart';

import '../models/player_growth.dart';

class GrowthCurveChart extends StatelessWidget {
  const GrowthCurveChart({
    super.key,
    required this.growthType,
  });

  final List<PlayerGrowth> growthType;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPaint(
        painter: _GrowthCurvePainter(growthType: growthType),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _GrowthCurvePainter extends CustomPainter {
  _GrowthCurvePainter({required this.growthType});

  final List<PlayerGrowth> growthType;

  @override
  void paint(Canvas canvas, Size size) {
    if (growthType.isEmpty) {
      return;
    }

    const padding = 24.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;
    final count = growthType.length;
    final stepX = count <= 1 ? chartWidth : chartWidth / (count - 1);

    void drawLine(Color color, int Function(PlayerGrowth g) pick) {
      final path = Path();
      for (var i = 0; i < count; i++) {
        final x = padding + stepX * i;
        final y = padding + chartHeight * (1 - pick(growthType[i]) / 10);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }

    final gridPaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1;
    for (var i = 0; i <= 10; i++) {
      final y = padding + chartHeight * (1 - i / 10);
      canvas.drawLine(Offset(padding, y), Offset(size.width - padding, y), gridPaint);
    }

    drawLine(Colors.blue, (g) => g.speed);
    drawLine(Colors.green, (g) => g.technique);
    drawLine(Colors.red, (g) => g.power);

    final labelStyle = TextStyle(color: Colors.white70, fontSize: 10);
    for (var i = 0; i < count; i++) {
      final x = padding + stepX * i;
      final tp = TextPainter(
        text: TextSpan(text: '${i + 1}기', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - 16));
    }
  }

  @override
  bool shouldRepaint(covariant _GrowthCurvePainter oldDelegate) {
    return !identical(oldDelegate.growthType, growthType);
  }
}
