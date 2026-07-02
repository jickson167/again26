import 'package:flutter/material.dart';

import '../models/formation.dart';
import '../models/key_position.dart';
import '../utils/formation_display.dart';
import 'formation_pitch_diagram.dart';
import 'game_stat_bar.dart';

class FormationDetailCard extends StatefulWidget {
  const FormationDetailCard({
    super.key,
    required this.formation,
    required this.keyPositionsById,
    this.editableComment = false,
    this.onSaveComment,
  });

  final Formation formation;
  final Map<String, KeyPosition> keyPositionsById;
  final bool editableComment;
  final Future<void> Function(String comment)? onSaveComment;

  @override
  State<FormationDetailCard> createState() => _FormationDetailCardState();
}

class _FormationDetailCardState extends State<FormationDetailCard> {
  late TextEditingController _commentController;
  bool _savingComment = false;

  FormationDisplay get _display => FormationDisplay(widget.formation);

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(text: _display.comment);
  }

  @override
  void didUpdateWidget(covariant FormationDetailCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.formation != widget.formation) {
      _commentController.text = _display.comment;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _saveComment() async {
    if (widget.onSaveComment == null) {
      return;
    }
    setState(() => _savingComment = true);
    try {
      await widget.onSaveComment!(_commentController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('코멘트가 저장되었습니다.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingComment = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final display = _display;
    final keyIds = display.keyPositionIds;
    final tactical = display.tacticalType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (display.needsReimport)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade700),
            ),
            child: const Text(
              '데이터가 옛 CSV 버그로 깨져 있습니다. 포메이션 CSV를 다시 드래그해서 가져오세요.',
            ),
          ),
        _SectionHeader(
          title: '포메이션 정보',
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.red.shade800, Colors.red.shade900]),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FormationPitchDiagram(lineCounts: display.lineCounts),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tactical,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        display.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '키 포지션',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      for (var i = 0; i < keyIds.length; i++)
                        _HeaderKeyPositionRow(
                          index: i + 1,
                          keyPosition: widget.keyPositionsById[keyIds[i]],
                          fallbackId: keyIds[i],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _SectionHeader(
          title: '데이터',
          child: Column(
            children: [
              GameStatBar(
                label: '유형',
                value: _tacticalValue(tactical),
                color: Colors.blue,
              ),
              GameStatBar(
                label: '공격성',
                value: _attackValue(tactical),
                color: Colors.green,
              ),
              GameStatBar(
                label: '안정성',
                value: _stabilityValue(tactical),
                color: Colors.red,
              ),
            ],
          ),
        ),
        _SectionHeader(
          title: '코멘트',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.editableComment)
                TextField(
                  controller: _commentController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: '포메이션 설명 (일반인도 읽을 수 있는 문장)',
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    display.comment.isNotEmpty
                        ? display.comment
                        : '등록된 코멘트가 없습니다.',
                  ),
                ),
              if (widget.editableComment) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _savingComment ? null : _saveComment,
                    icon: _savingComment
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('코멘트 저장'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  int _tacticalValue(String? type) {
    if (type == null || type.isEmpty) {
      return 5;
    }
    if (type.contains('공격') || type.contains('총공격')) {
      return 8;
    }
    if (type.contains('수비') || type.contains('철벽') || type.contains('잠그')) {
      return 3;
    }
    return 5;
  }

  int _attackValue(String? type) {
    if (type == null || type.isEmpty) {
      return 5;
    }
    if (type.contains('공격') || type.contains('역습') || type.contains('총공격')) {
      return 8;
    }
    if (type.contains('수비') || type.contains('안정') || type.contains('잠그')) {
      return 3;
    }
    return 5;
  }

  int _stabilityValue(String? type) {
    return 10 - _attackValue(type);
  }
}

class _HeaderKeyPositionRow extends StatelessWidget {
  const _HeaderKeyPositionRow({
    required this.index,
    required this.keyPosition,
    required this.fallbackId,
  });

  final int index;
  final KeyPosition? keyPosition;
  final String fallbackId;

  @override
  Widget build(BuildContext context) {
    final title = keyPosition?.name ?? _humanizeId(fallbackId);
    final desc = keyPosition?.description ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.amber.shade700,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (desc.isNotEmpty)
                  Text(
                    desc,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _humanizeId(String id) {
    return id.replaceAll('kp_', '').replaceAll('_', ' ');
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: const Color(0xFF374151),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: child,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
