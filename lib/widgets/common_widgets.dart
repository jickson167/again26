import 'package:flutter/material.dart';

class StatBar extends StatelessWidget {
  const StatBar({
    super.key,
    required this.label,
    required this.value,
    this.max = 10,
  });

  final String label;
  final int value;
  final int max;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = max == 0 ? 0.0 : value / max;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 10,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 28,
            child: Text('$value', textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

class DualStatBar extends StatelessWidget {
  const DualStatBar({
    super.key,
    required this.labelLeft,
    required this.labelRight,
    required this.leftValue,
    required this.rightValue,
    this.max = 10,
  });

  final String labelLeft;
  final String labelRight;
  final int leftValue;
  final int rightValue;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(labelLeft),
            Text(labelRight),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: leftValue / max,
                minHeight: 10,
                color: Colors.blue,
                backgroundColor: Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: rightValue / max,
                    minHeight: 10,
                    color: Colors.orange,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text('$labelLeft $leftValue / $labelRight $rightValue'),
      ],
    );
  }
}

class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.name,
    this.portraitUrl,
    this.radius = 28,
  });

  final String name;
  final String? portraitUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (portraitUrl != null && portraitUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(portraitUrl!),
        onBackgroundImageError: (_, _) {},
        child: const SizedBox.shrink(),
      );
    }

    return CircleAvatar(
      radius: radius,
      child: Text(name.isNotEmpty ? name.characters.first : '?'),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message = '불러오는 중...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(message),
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ],
      ),
    );
  }
}

class StatSliderField extends StatelessWidget {
  const StatSliderField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.max = 10,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $value'),
        Slider(
          value: value.toDouble(),
          min: 0,
          max: max.toDouble(),
          divisions: max,
          label: '$value',
          onChanged: (next) => onChanged(next.round()),
        ),
      ],
    );
  }
}
