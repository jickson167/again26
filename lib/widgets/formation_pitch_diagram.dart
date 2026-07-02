import 'package:flutter/material.dart';

/// 포메이션 이름(예: 3-2-4-1)에 맞춰 경기장 + 파란 점 표시
class FormationPitchDiagram extends StatelessWidget {
  const FormationPitchDiagram({
    super.key,
    required this.lineCounts,
    this.width = 120,
    this.height = 140,
  });

  final List<int> lineCounts;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _FormationPitchPainter(lineCounts: lineCounts),
        size: Size(width, height),
      ),
    );
  }
}

class _FormationPitchPainter extends CustomPainter {
  _FormationPitchPainter({required this.lineCounts});

  final List<int> lineCounts;

  @override
  void paint(Canvas canvas, Size size) {
    final fieldRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      fieldRect,
      Paint()..color = const Color(0xFF14532D),
    );
    canvas.drawRRect(
      fieldRect,
      Paint()
        ..color = Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final linePaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;
    canvas.drawRect(
      Rect.fromLTWH(6, 6, size.width - 12, size.height - 12),
      linePaint,
    );
    canvas.drawLine(
      Offset(6, size.height * 0.55),
      Offset(size.width - 6, size.height * 0.55),
      linePaint,
    );

    final rows = lineCounts.isEmpty ? [4, 4, 2] : lineCounts;
    const topPad = 14.0;
    const bottomPad = 10.0;
    final usableHeight = size.height - topPad - bottomPad;

    for (var row = 0; row < rows.length; row++) {
      final players = rows[row];
      if (players <= 0) {
        continue;
      }
      final y = topPad + usableHeight * (row + 0.5) / rows.length;
      for (var col = 0; col < players; col++) {
        final x = size.width * (col + 1) / (players + 1);
        canvas.drawCircle(
          Offset(x, y),
          5,
          Paint()..color = Colors.blue.shade400,
        );
        canvas.drawCircle(
          Offset(x, y),
          5,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FormationPitchPainter oldDelegate) {
    return oldDelegate.lineCounts != lineCounts;
  }
}
