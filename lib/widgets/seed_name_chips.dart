import 'package:flutter/material.dart';

class SeedNameChips extends StatelessWidget {
  const SeedNameChips({
    super.key,
    required this.seedNames,
    this.dense = false,
    this.showLabel = false,
    this.onDarkBackground = false,
  });

  final List<String> seedNames;
  final bool dense;
  final bool showLabel;
  final bool onDarkBackground;

  @override
  Widget build(BuildContext context) {
    final chips = Wrap(
      spacing: dense ? 4 : 6,
      runSpacing: dense ? 4 : 6,
      children: seedNames.map((name) => _SeedPill(
            label: name,
            dense: dense,
            onDarkBackground: onDarkBackground,
          )).toList(),
    );

    if (!showLabel) {
      return chips;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '시드 :',
          style: TextStyle(
            color: onDarkBackground ? Colors.white70 : Colors.black54,
            fontSize: dense ? 12 : 13,
            height: dense ? 1.6 : 1.8,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(child: chips),
      ],
    );
  }
}

class _SeedPill extends StatelessWidget {
  const _SeedPill({
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
        horizontal: dense ? 8 : 10,
        vertical: dense ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: onDarkBackground
            ? Colors.white.withValues(alpha: 0.18)
            : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: onDarkBackground ? Colors.white54 : const Color(0xFF93C5FD),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: dense ? 11 : 12,
          color: onDarkBackground ? Colors.white : const Color(0xFF1E40AF),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
