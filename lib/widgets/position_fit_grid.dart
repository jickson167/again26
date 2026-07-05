import 'package:flutter/material.dart';

import '../models/field_position_layout.dart';

Color positionFitColor(int value) {
  if (value >= 7) {
    return const Color(0xFFB91C1C);
  }
  if (value >= 4) {
    return const Color(0xFFEA580C);
  }
  return const Color(0xFF16A34A);
}

class PositionFitGrid extends StatelessWidget {
  const PositionFitGrid({
    super.key,
    required this.positionFit,
  });

  final Map<int, int> positionFit;

  static const _cellAspectRatio = 56 / 44;
  static const _cellGap = 4.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF14532D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          for (final row in FieldPositionLayout.gridRows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  for (var i = 0; i < row.length; i++) ...[
                    if (i > 0) const SizedBox(width: _cellGap),
                    Expanded(
                      child: row[i] == null
                          ? const AspectRatio(
                              aspectRatio: _cellAspectRatio,
                              child: SizedBox.shrink(),
                            )
                          : AspectRatio(
                              aspectRatio: _cellAspectRatio,
                              child: _PositionCell(
                                label: FieldPositionLayout.labels[row[i]!] ?? 'P${row[i]}',
                                value: positionFit[row[i]!] ?? 0,
                              ),
                            ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PositionCell extends StatelessWidget {
  const _PositionCell({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final color = positionFitColor(value);
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black26),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
