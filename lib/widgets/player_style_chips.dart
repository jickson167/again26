import 'package:flutter/material.dart';

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
