import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

import '../services/csv_file_loader.dart';

class CsvDropImportZone extends StatefulWidget {
  const CsvDropImportZone({
    super.key,
    required this.label,
    required this.onImport,
    this.busy = false,
  });

  final String label;
  final Future<void> Function(String content) onImport;
  final bool busy;

  @override
  State<CsvDropImportZone> createState() => _CsvDropImportZoneState();
}

class _CsvDropImportZoneState extends State<CsvDropImportZone> {
  bool _dragging = false;

  Future<void> _handleContent(String content, {required String source}) async {
    if (widget.busy || content.trim().isEmpty) {
      return;
    }

    try {
      await widget.onImport(content);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV 가져오기 실패 ($source): $error')),
      );
    }
  }

  Future<void> _pickFile() async {
    final content = await CsvFileLoader.pickCsvText();
    if (content == null) {
      return;
    }
    await _handleContent(content, source: '파일 선택');
  }

  Future<void> _handleDrop(DropDoneDetails details) async {
    setState(() => _dragging = false);

    for (final file in details.files) {
      final name = file.name;
      if (!CsvFileLoader.isCsvFileName(name)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('CSV 파일만 업로드할 수 있습니다: $name')),
          );
        }
        continue;
      }

      final bytes = await file.readAsBytes();
      await _handleContent(
        CsvFileLoader.decodeBytes(bytes),
        source: name,
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = _dragging
        ? theme.colorScheme.primary
        : theme.colorScheme.outline;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: DropTarget(
        onDragEntered: (_) => setState(() => _dragging = true),
        onDragExited: (_) => setState(() => _dragging = false),
        onDragDone: _handleDrop,
        child: Material(
          color: _dragging
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: borderColor,
              width: _dragging ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: widget.busy ? null : _pickFile,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  Icon(
                    _dragging ? Icons.file_download : Icons.upload_file,
                    size: 36,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dragging
                              ? '여기에 CSV를 놓으세요'
                              : 'CSV 파일을 드래그하거나 클릭하여 업로드',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (widget.busy)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(Icons.touch_app, color: theme.colorScheme.outline),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
