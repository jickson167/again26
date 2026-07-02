import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/formation_shape.dart';
import '../utils/formation_slot_layout.dart';

/// 포메이션 미니맵 — 줄별 10명 배치 + 키포지션 slot 별표 (GK 점 없음)
class FormationPitchDiagram extends StatelessWidget {
  const FormationPitchDiagram({
    super.key,
    required this.formationName,
    required this.keySlots,
    this.width = 120,
    this.height = 150,
    this.showFormationDots = true,
  });

  final String formationName;
  final Set<int> keySlots;

  /// GK(13) 키포지션 별표는 제외하고 필드 10명만 표시
  final bool showFormationDots;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _FormationPitchPainter(
          formationName: formationName,
          keySlots: keySlots,
          showFormationDots: showFormationDots,
        ),
        size: Size(width, height),
      ),
    );
  }
}

class _FormationPitchPainter extends CustomPainter {
  _FormationPitchPainter({
    required this.formationName,
    required this.keySlots,
    required this.showFormationDots,
  });

  final String formationName;
  final Set<int> keySlots;
  final bool showFormationDots;

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
      Offset(6, size.height * 0.58),
      Offset(size.width - 6, size.height * 0.58),
      linePaint,
    );

    if (showFormationDots) {
      for (final center in FormationShape.lineDotOffsets(formationName, size)) {
        if (_isNearKeyStar(center, size)) {
          continue;
        }
        _drawBlueDot(canvas, center);
      }
    }

    for (final slot in keySlots) {
      final center = FormationSlotLayout.slotOffset(slot, size: size);
      if (slot != 13) {
        _drawBlueDot(canvas, center);
      }
      _drawStar(canvas, center);
    }
  }

  bool _isNearKeyStar(Offset dot, Size size) {
    for (final slot in keySlots) {
      if (slot == 13) {
        continue;
      }
      final star = FormationSlotLayout.slotOffset(slot, size: size);
      if ((dot - star).distance < 10) {
        return true;
      }
    }
    return false;
  }

  void _drawBlueDot(Canvas canvas, Offset center) {
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
      Paint()..color = Colors.amber.shade800.withValues(alpha: 0.92),
    );
    canvas.drawPath(path, Paint()..color = Colors.amber.shade200);
  }

  @override
  bool shouldRepaint(covariant _FormationPitchPainter oldDelegate) {
    return oldDelegate.formationName != formationName ||
        oldDelegate.keySlots != keySlots ||
        oldDelegate.showFormationDots != showFormationDots;
  }
}
