import 'package:flutter/material.dart';

class GameStatBar extends StatelessWidget {
  const GameStatBar({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.max = 10,
    this.compact = false,
  });

  final String label;
  final int value;
  final Color color;
  final int max;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final labelWidth = compact ? 44.0 : 72.0;
    final valueWidth = compact ? 14.0 : 20.0;
    final fontSize = compact ? 10.0 : 12.0;
    final barHeight = compact ? 9.0 : 12.0;
    final segmentGap = compact ? 1.0 : 2.0;
    final verticalPadding = compact ? 4.0 : 3.0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < max; i++)
                  Expanded(
                    child: Container(
                      height: barHeight,
                      margin: EdgeInsets.only(right: i == max - 1 ? 0 : segmentGap),
                      decoration: BoxDecoration(
                        color: i < value ? color : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: compact ? 3 : 6),
          SizedBox(
            width: valueWidth,
            child: Text(
              '$value',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: compact ? 10 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GameDualSlider extends StatelessWidget {
  const GameDualSlider({
    super.key,
    required this.leftLabel,
    required this.rightLabel,
    required this.leftValue,
    required this.rightValue,
    this.max = 10,
    this.compact = false,
  });

  final String leftLabel;
  final String rightLabel;
  final int leftValue;
  final int rightValue;
  final int max;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final total = leftValue + rightValue;
    final leftRatio = total == 0 ? 0.5 : leftValue / total;
    final labelSize = compact ? 10.0 : 12.0;
    final barHeight = compact ? 8.0 : 10.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(leftLabel, style: TextStyle(fontSize: labelSize)),
            Text(rightLabel, style: TextStyle(fontSize: labelSize)),
          ],
        ),
        SizedBox(height: compact ? 3 : 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: barHeight,
            child: Row(
              children: [
                Expanded(
                  flex: (leftRatio * 100).round().clamp(1, 99),
                  child: Container(color: Colors.blue),
                ),
                Expanded(
                  flex: ((1 - leftRatio) * 100).round().clamp(1, 99),
                  child: Container(color: Colors.orange),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: compact ? 4 : 2),
        Text(
          '$leftLabel $leftValue · $rightLabel $rightValue',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: compact ? 9 : null,
              ),
        ),
      ],
    );
  }
}
