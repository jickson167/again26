import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/formation_shape.dart';

/// 정사각형 포메이션 미니맵 (GK 포함 11점 + 키포지션 별표)
class FormationPitchDiagram extends StatelessWidget {
  const FormationPitchDiagram({
    super.key,
    required this.formationName,
    required this.keySlots,
    this.size = 136,
    this.showAllDots = true,
    this.compact = false,
  });

  final String formationName;
  final Set<int> keySlots;
  final double size;
  final bool showAllDots;

  /// 키포지션 미니맵: 전체 포메이션 점을 옅게 + 해당 별만 강조
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FormationPitchPainter(
          formationName: formationName,
          keySlots: keySlots,
          showAllDots: showAllDots,
          compact: compact,
        ),
        size: Size(size, size),
      ),
    );
  }
}

class _FormationPitchPainter extends CustomPainter {
  _FormationPitchPainter({
    required this.formationName,
    required this.keySlots,
    required this.showAllDots,
    required this.compact,
  });

  final String formationName;
  final Set<int> keySlots;
  final bool showAllDots;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    _drawPitch(canvas, size);

    final keyCenters = {
      for (final slot in keySlots)
        slot: FormationPitchLayout.keySlotOffset(slot, formationName, size),
    };

    if (showAllDots) {
      for (final center in FormationPitchLayout.allDotOffsets(formationName, size)) {
        if (_isKeyCenter(center, keyCenters.values)) {
          continue;
        }
        _drawDot(
          canvas,
          center,
          fill: compact ? Colors.blue.shade400.withValues(alpha: 0.35) : Colors.blue.shade400,
          radius: compact ? 3.6 : 5.5,
        );
      }
    }

    for (final entry in keyCenters.entries) {
      if (entry.key != 13) {
        _drawDot(canvas, entry.value, fill: Colors.blue.shade400, radius: compact ? 4.0 : 5.5);
      }
      _drawStar(canvas, entry.value, compact: compact);
    }
  }

  void _drawPitch(Canvas canvas, Size size) {
    final fieldRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(8),
    );
    canvas.drawRRect(fieldRect, Paint()..color = const Color(0xFF166534));
    canvas.drawRRect(
      fieldRect,
      Paint()
        ..color = const Color(0xFF3B82F6).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final inset = size.width * 0.05;
    canvas.drawRect(
      Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2),
      line,
    );

    final boxW = size.width * 0.48;
    final boxH = size.height * 0.16;
    final boxCenterY = size.height * FormationPitchLayout.gkYRatio;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, boxCenterY),
        width: boxW,
        height: boxH,
      ),
      line,
    );

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width / 2, inset + 2),
        width: size.width * 0.38,
        height: size.width * 0.38,
      ),
      0,
      math.pi,
      false,
      line,
    );
  }

  bool _isKeyCenter(Offset dot, Iterable<Offset> keys) {
    for (final key in keys) {
      if ((dot - key).distance < 8) {
        return true;
      }
    }
    return false;
  }

  void _drawDot(
    Canvas canvas,
    Offset center, {
    required Color fill,
    required double radius,
  }) {
    canvas.drawCircle(center, radius, Paint()..color = fill);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawStar(Canvas canvas, Offset center, {required bool compact}) {
    final outerRadius = compact ? 6.0 : 8.0;
    final innerRadius = compact ? 2.8 : 3.6;
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
      outerRadius + 1.2,
      Paint()..color = Colors.amber.shade800.withValues(alpha: 0.95),
    );
    canvas.drawPath(path, Paint()..color = Colors.amber.shade200);
  }

  @override
  bool shouldRepaint(covariant _FormationPitchPainter oldDelegate) {
    return oldDelegate.formationName != formationName ||
        oldDelegate.keySlots != keySlots ||
        oldDelegate.showAllDots != showAllDots ||
        oldDelegate.compact != compact;
  }
}
