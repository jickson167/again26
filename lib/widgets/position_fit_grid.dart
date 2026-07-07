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

  static const _cellWidth = 56.0;
  static const _cellHeight = 44.0;
  static const _cellGap = 6.0;
  static const _gridWidth = _cellWidth * 3 + _cellGap * 2;

  @override
  Widget build(BuildContext context) {
    final padding = compact ? 4.0 : 8.0;
    final rowGap = compact ? 2.0 : 3.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : _gridWidth + padding * 2;

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: maxWidth,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF14532D),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: SizedBox(
                    width: _gridWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final row in FieldPositionLayout.gridRows)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: rowGap),
                            child: _PositionRow(
                              slots: row,
                              positionFit: positionFit,
                              compact: compact,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PositionRow extends StatelessWidget {
  const _PositionRow({
    required this.slots,
    required this.positionFit,
    required this.compact,
  });

  final List<int?> slots;
  final Map<int, int> positionFit;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: PositionFitGrid._gridWidth,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < slots.length; i++) ...[
            if (i > 0) const SizedBox(width: PositionFitGrid._cellGap),
            if (slots[i] == null)
              const SizedBox(
                width: PositionFitGrid._cellWidth,
                height: PositionFitGrid._cellHeight,
              )
            else
              _PositionCell(
                label: FieldPositionLayout.labels[slots[i]!] ?? 'P${slots[i]}',
                value: positionFit[slots[i]!] ?? 0,
                compact: compact,
              ),
          ],
        ],
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
    return SizedBox(
      width: PositionFitGrid._cellWidth,
      height: PositionFitGrid._cellHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.black26),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 9 : 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$value',
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
