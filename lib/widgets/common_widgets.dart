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
          SizedBox(width: 28, child: Text('$value', textAlign: TextAlign.end)),
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
          children: [Text(labelLeft), Text(labelRight)],
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
    this.clipPortrait = true,
    this.portraitScale = 1.0,
  });

  final String name;
  final String? portraitUrl;
  final double radius;

  /// false면 아이콘 밖으로 넘어가는 이미지를 자르지 않습니다.
  final bool clipPortrait;

  /// 아이콘 한 변 대비 초상화 표시 배율.
  /// [clipPortrait]가 false일 때는 높이 기준으로 통일합니다 (가로는 비율 유지, 폭 맞춤 없음).
  final double portraitScale;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;

    if (portraitUrl != null && portraitUrl!.isNotEmpty) {
      if (clipPortrait) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: size,
            height: size,
            child: Image.network(
              portraitUrl!,
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
              errorBuilder: (_, _, _) =>
                  _PlayerAvatarFallback(name: name, size: size),
            ),
          ),
        );
      }

      // 높이를 일괄 통일. 가로는 원본 비율(폭에 맞추지 않음, 마스크 없음).
      return SizedBox(
        width: size,
        height: size,
        child: OverflowBox(
          alignment: Alignment.topCenter,
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: Image.network(
            portraitUrl!,
            height: size * portraitScale,
            alignment: Alignment.topCenter,
            errorBuilder: (_, _, _) =>
                _PlayerAvatarFallback(name: name, size: size),
          ),
        ),
      );
    }

    return _PlayerAvatarFallback(name: name, size: size);
  }
}

class _PlayerAvatarFallback extends StatelessWidget {
  const _PlayerAvatarFallback({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(name.isNotEmpty ? name.characters.first : '?'),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.child});

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
  const ErrorView({super.key, required this.message, this.onRetry});

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
