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
    this.compact = false,
  });

  final Map<int, int> positionFit;
  final bool compact;

  static const _cellAspectRatio = 56 / 44;

  @override
  Widget build(BuildContext context) {
    final padding = compact ? 4.0 : 8.0;
    final cellGap = compact ? 2.0 : 4.0;
    final rowGap = compact ? 2.0 : 3.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: const Color(0xFF14532D),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final row in FieldPositionLayout.gridRows)
              Padding(
                padding: EdgeInsets.symmetric(vertical: rowGap),
                child: Row(
                  children: [
                    for (var i = 0; i < row.length; i++) ...[
                      if (i > 0) SizedBox(width: cellGap),
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
                                  compact: compact,
                                ),
                              ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PositionCell extends StatelessWidget {
  const _PositionCell({
    required this.label,
    required this.value,
    this.compact = false,
  });

  final String label;
  final int value;
  final bool compact;

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
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 8 : 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$value',
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 11 : 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
