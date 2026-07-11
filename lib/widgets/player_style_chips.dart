import 'package:flutter/material.dart';

/// 랭크별 플레이 스타일 개수 가이드 (한 줄, 공간 부족 시 글자 축소).
class PlayerStyleRankGuide extends StatelessWidget {
  const PlayerStyleRankGuide({super.key});

  static const _guideText =
      '랭크별 스타일 개수 · 1~2랭크 1~2개 · 3~4랭크 2~3개 · 5~6랭크 3~4개';

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[700],
            ) ??
        TextStyle(fontSize: 12, color: Colors.grey[700]);

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        _guideText,
        style: baseStyle,
        maxLines: 1,
      ),
    );
  }
}

class PlayerStyleChips extends StatelessWidget {
  const PlayerStyleChips({
    super.key,
    required this.styleLabels,
    this.dense = false,
    this.onDarkBackground = false,
  });

  final List<String> styleLabels;
  final bool dense;
  final bool onDarkBackground;

  @override
  Widget build(BuildContext context) {
    if (styleLabels.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: dense ? 4 : 6,
      runSpacing: dense ? 4 : 6,
      children: styleLabels
          .map(
            (label) => _StylePill(
              label: label,
              dense: dense,
              onDarkBackground: onDarkBackground,
            ),
          )
          .toList(),
    );
  }
}

class _StylePill extends StatelessWidget {
  const _StylePill({
    required this.label,
    required this.dense,
    required this.onDarkBackground,
  });

  final String label;
  final bool dense;
  final bool onDarkBackground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 9,
        vertical: dense ? 1 : 3,
      ),
      decoration: BoxDecoration(
        color: onDarkBackground
            ? Colors.white.withValues(alpha: 0.14)
            : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: onDarkBackground ? Colors.white38 : const Color(0xFF86EFAC),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: dense ? 10 : 11,
          color: onDarkBackground ? Colors.white : const Color(0xFF166534),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
