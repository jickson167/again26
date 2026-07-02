import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/formation_slot_layout.dart';

/// 13칸 슬롯 미니맵 + 키포지션 slot 별표
class FormationPitchDiagram extends StatelessWidget {
  const FormationPitchDiagram({
    super.key,
    required this.keySlots,
    this.width = 120,
    this.height = 150,
  });

  final Set<int> keySlots;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _FormationPitchPainter(keySlots: keySlots),
        size: Size(width, height),
      ),
    );
  }
}

class _FormationPitchPainter extends CustomPainter {
  _FormationPitchPainter({required this.keySlots});

  final Set<int> keySlots;

  @override
  void paint(Canvas canvas, Size size) {
    final fieldRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(6),
    );
    canvas.drawRRect(fieldRect, Paint()..color = const Color(0xFF14532D));
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

    for (var slot = 1; slot <= 13; slot++) {
      final center = FormationSlotLayout.slotOffset(slot, size: size);
      final isKey = keySlots.contains(slot);
      if (isKey) {
        continue;
      }
      canvas.drawCircle(center, 4, Paint()..color = Colors.blue.shade400);
      canvas.drawCircle(
        center,
        4,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    for (final slot in keySlots) {
      _drawStar(canvas, FormationSlotLayout.slotOffset(slot, size: size));
    }
  }

  void _drawStar(Canvas canvas, Offset center) {
    const outerRadius = 7.0;
    const innerRadius = 3.2;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = (math.pi / 2) + (i * math.pi / 5);
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy - radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawCircle(
      center,
      outerRadius + 1.5,
      Paint()..color = Colors.amber.shade800,
    );
    canvas.drawPath(path, Paint()..color = Colors.amber.shade200);
  }

  @override
  bool shouldRepaint(covariant _FormationPitchPainter oldDelegate) {
    return oldDelegate.keySlots != keySlots;
  }
}
