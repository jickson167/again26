import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

import '../utils/portrait_data_url.dart';
import 'common_widgets.dart';

class PortraitDropAvatar extends StatefulWidget {
  const PortraitDropAvatar({
    super.key,
    required this.name,
    this.portraitUrl,
    this.radius = 28,
    required this.onImageDropped,
    this.uploading = false,
  });

  final String name;
  final String? portraitUrl;
  final double radius;
  final Future<void> Function(Uint8List bytes, String fileName) onImageDropped;
  final bool uploading;

  @override
  State<PortraitDropAvatar> createState() => _PortraitDropAvatarState();
}

class _PortraitDropAvatarState extends State<PortraitDropAvatar> {
  bool _dragging = false;

  Future<void> _handleDrop(DropDoneDetails details) async {
    setState(() => _dragging = false);
    if (widget.uploading) {
      return;
    }

    for (final file in details.files) {
      final name = file.name;
      if (!isPortraitImageFileName(name)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('이미지 파일만 업로드할 수 있습니다: $name')),
          );
        }
        continue;
      }

      try {
        final bytes = await file.readAsBytes();
        await widget.onImageDropped(bytes, name);
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('이미지 업로드 실패: $error')),
          );
        }
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.radius * 2;
    final theme = Theme.of(context);
    final borderColor = _dragging
        ? theme.colorScheme.primary
        : theme.colorScheme.outline.withValues(alpha: 0.35);

    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: _handleDrop,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: borderColor,
                    width: _dragging ? 2 : 1,
                  ),
                  color: _dragging
                      ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
                      : null,
                ),
                child: PlayerAvatar(
                  name: widget.name,
                  portraitUrl: widget.portraitUrl,
                  radius: widget.radius,
                ),
              ),
            ),
            if (widget.uploading)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            if (_dragging)
              Positioned(
                left: 0,
                right: 0,
                bottom: -2,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '교체',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
