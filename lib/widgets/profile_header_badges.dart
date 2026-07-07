import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/profile_badge_labels.dart';

/// 선수·감독 상세 카드 상단 — 포지션 배지 · 국기 · 랭크(별) 나란히.
class ProfileHeaderBadges extends StatelessWidget {
  const ProfileHeaderBadges({
    super.key,
    required this.positionLabel,
    this.flagUrl,
    this.rank,
  });

  final String positionLabel;
  final String? flagUrl;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PositionBadgeImage(label: positionLabel),
        const SizedBox(width: 6),
        if (flagUrl != null && flagUrl!.isNotEmpty) ...[
          NationFlagImage(url: flagUrl!),
          const SizedBox(width: 6),
        ],
        if (rank != null && rank! >= 1 && rank! <= 5)
          RankStarBadge(rank: rank!),
      ],
    );
  }
}

class PositionBadgeImage extends StatelessWidget {
  const PositionBadgeImage({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final bg = positionBadgeColor(label);

    return Container(
      constraints: const BoxConstraints(minWidth: 34, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.white24),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 1, offset: Offset(0, 1)),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          height: 1,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class NationFlagImage extends StatelessWidget {
  const NationFlagImage({super.key, required this.url, this.height = 20});

  final String url;
  final double height;

  @override
  Widget build(BuildContext context) {
    final width = height * 1.45;
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => Container(
          width: width,
          height: height,
          color: Colors.black26,
          alignment: Alignment.center,
          child: const Icon(Icons.flag, size: 12, color: Colors.white54),
        ),
      ),
    );
  }
}

class RankStarBadge extends StatelessWidget {
  const RankStarBadge({super.key, required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(24, 24),
            painter: _StarPainter(color: const Color(0xFF2E9E46)),
          ),
          Text(
            '$rank',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              height: 1,
              shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
            ),
          ),
        ],
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    const points = 5;
    final outer = size.width * 0.48;
    final inner = outer * 0.42;

    for (var i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outer : inner;
      final angle = (i * 3.1415926535 / points) - 3.1415926535 / 2;
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
