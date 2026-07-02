import 'package:flutter/material.dart';

class GameStatBar extends StatelessWidget {
  const GameStatBar({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.max = 10,
  });

  final String label;
  final int value;
  final Color color;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < max; i++)
                  Expanded(
                    child: Container(
                      height: 12,
                      margin: EdgeInsets.only(right: i == max - 1 ? 0 : 2),
                      decoration: BoxDecoration(
                        color: i < value ? color : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 20,
            child: Text(
              '$value',
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold),
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
  });

  final String leftLabel;
  final String rightLabel;
  final int leftValue;
  final int rightValue;
  final int max;

  @override
  Widget build(BuildContext context) {
    final total = leftValue + rightValue;
    final leftRatio = total == 0 ? 0.5 : leftValue / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(leftLabel, style: const TextStyle(fontSize: 12)),
            Text(rightLabel, style: const TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 10,
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
        const SizedBox(height: 2),
        Text(
          '$leftLabel $leftValue · $rightLabel $rightValue',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
