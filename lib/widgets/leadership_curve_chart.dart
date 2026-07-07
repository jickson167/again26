import 'package:flutter/material.dart';

class LeadershipCurveChart extends StatelessWidget {
  const LeadershipCurveChart({
    super.key,
    required this.values,
    this.maxValue = 110,
  });

  final List<int> values;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPaint(
        painter: _LeadershipCurvePainter(values: values, maxValue: maxValue),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _LeadershipCurvePainter extends CustomPainter {
  _LeadershipCurvePainter({
    required this.values,
    required this.maxValue,
  });

  final List<int> values;
  final int maxValue;

  static const _lineColor = Color(0xFFBB86FC);
  static const _pointColor = Color(0xFFCE93D8);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }

    const leftPadding = 34.0;
    const rightPadding = 8.0;
    const topPadding = 18.0;
    const bottomPadding = 28.0;
    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;
    final count = values.length;
    final stepX = count <= 1 ? chartWidth : chartWidth / (count - 1);
    final yMax = maxValue <= 0 ? 110 : maxValue;

    final gridPaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1;
    for (var tick = 0; tick <= yMax; tick += 20) {
      final y = topPadding + chartHeight * (1 - tick / yMax);
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: '$tick',
          style: const TextStyle(color: Colors.white54, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPadding - tp.width - 4, y - tp.height / 2));
    }

    double yFor(int value) {
      final clamped = value.clamp(0, yMax);
      return topPadding + chartHeight * (1 - clamped / yMax);
    }

    final path = Path();
    final points = <Offset>[];
    for (var i = 0; i < count; i++) {
      final x = leftPadding + stepX * i;
      final y = yFor(values[i]);
      points.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = _lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      canvas.drawCircle(point, 4, Paint()..color = _pointColor);
      canvas.drawCircle(point, 2, Paint()..color = Colors.white);

      if (values[i] > 0) {
        final label = TextPainter(
          text: TextSpan(
            text: '${values[i]}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        label.paint(
          canvas,
          Offset(point.dx - label.width / 2, point.dy - label.height - 6),
        );
      }
    }

    final axisStyle = TextStyle(color: Colors.white70, fontSize: 9);
    for (var i = 0; i < count; i++) {
      final x = leftPadding + stepX * i;
      final tp = TextPainter(
        text: TextSpan(text: '${i + 1}', style: axisStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - bottomPadding + 6));
    }

    final periodLabel = TextPainter(
      text: TextSpan(text: '(기)', style: axisStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    periodLabel.paint(
      canvas,
      Offset(size.width - rightPadding - periodLabel.width, size.height - bottomPadding + 6),
    );
  }

  @override
  bool shouldRepaint(covariant _LeadershipCurvePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.maxValue != maxValue;
  }
}
