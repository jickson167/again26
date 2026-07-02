import 'package:flutter/material.dart';

import '../models/formation.dart';
import '../models/key_position.dart';
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

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(text: widget.formation.comment ?? '');
  }

  @override
  void didUpdateWidget(covariant FormationDetailCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.formation.comment != widget.formation.comment) {
      _commentController.text = widget.formation.comment ?? '';
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
    final formation = widget.formation;
    final keyIds = formation.keyPositionIds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                SizedBox(
                  width: 120,
                  height: 140,
                  child: _FormationPitch(name: formation.name),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (formation.tacticalType != null)
                        Text(
                          formation.tacticalType!,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      Text(
                        formation.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('키 포지션', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: keyIds.map((id) {
                          final kp = widget.keyPositionsById[id];
                          return Chip(
                            avatar: const Icon(Icons.star, color: Colors.amber, size: 16),
                            label: Text(kp?.name ?? id),
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            labelStyle: const TextStyle(color: Colors.white),
                          );
                        }).toList(),
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
                value: _tacticalValue(formation.tacticalType),
                color: Colors.blue,
              ),
              GameStatBar(
                label: '공격성',
                value: _attackValue(formation.tacticalType),
                color: Colors.green,
              ),
              GameStatBar(
                label: '안정성',
                value: _stabilityValue(formation.tacticalType),
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
                    hintText: '포메이션 코멘트',
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
                    formation.comment?.isNotEmpty == true
                        ? formation.comment!
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
        _SectionHeader(
          title: '키 포지션',
          child: Column(
            children: [
              for (var i = 0; i < keyIds.length; i++)
                _KeyPositionTile(
                  index: i + 1,
                  keyPosition: widget.keyPositionsById[keyIds[i]],
                  fallbackId: keyIds[i],
                ),
            ],
          ),
        ),
      ],
    );
  }

  int _tacticalValue(String? type) {
    if (type == null) {
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
    if (type == null) {
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

class _KeyPositionTile extends StatelessWidget {
  const _KeyPositionTile({
    required this.index,
    required this.keyPosition,
    required this.fallbackId,
  });

  final int index;
  final KeyPosition? keyPosition;
  final String fallbackId;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.amber.shade700,
            child: Text('$index', style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  keyPosition?.name ?? fallbackId,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (keyPosition != null) ...[
                  Text(
                  '${keyPosition!.mainStat} / ${keyPosition!.subStat} · ${keyPosition!.simplePosition.label}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(keyPosition!.description ?? ''),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormationPitch extends StatelessWidget {
  const _FormationPitch({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF14532D),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white24),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          ...List.generate(10, (i) {
            return Positioned(
              left: 20 + (i % 3) * 28.0,
              top: 20 + (i ~/ 3) * 24.0,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        ],
      ),
    );
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
