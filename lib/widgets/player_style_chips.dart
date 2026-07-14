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
    this.panelStyle = false,
    this.maxLines = 0,
  });

  final List<String> styleLabels;
  final bool dense;
  final bool onDarkBackground;

  /// 팀편성 패널용: 흰 테두리 + 반투명 검정 배경.
  final bool panelStyle;

  /// 0이면 제한 없음. 초과 시 전체 스케일 다운.
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    if (styleLabels.isEmpty) {
      return const SizedBox.shrink();
    }

    final wrap = Wrap(
      spacing: dense ? 4 : 6,
      runSpacing: dense ? 4 : 6,
      children: styleLabels
          .map(
            (label) => _StylePill(
              label: label,
              dense: dense,
              onDarkBackground: onDarkBackground,
              panelStyle: panelStyle,
            ),
          )
          .toList(),
    );

    if (maxLines <= 0) {
      return wrap;
    }

    final lineH = dense ? 20.0 : 24.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: lineH * maxLines),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: constraints.maxWidth,
              child: wrap,
            ),
          ),
        );
      },
    );
  }
}

class _StylePill extends StatelessWidget {
  const _StylePill({
    required this.label,
    required this.dense,
    required this.onDarkBackground,
    required this.panelStyle,
  });

  final String label;
  final bool dense;
  final bool onDarkBackground;
  final bool panelStyle;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color fg;
    if (panelStyle) {
      bg = Colors.black.withValues(alpha: 0.45);
      border = Colors.white;
      fg = Colors.white;
    } else if (onDarkBackground) {
      bg = Colors.white.withValues(alpha: 0.14);
      border = Colors.white38;
      fg = Colors.white;
    } else {
      bg = const Color(0xFFF0FDF4);
      border = const Color(0xFF86EFAC);
      fg = const Color(0xFF166534);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 9,
        vertical: dense ? 1 : 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: panelStyle ? 1 : 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: dense ? 10 : 11,
          color: fg,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
