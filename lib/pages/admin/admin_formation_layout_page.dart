import 'package:flutter/material.dart';

import '../../models/formation.dart';
import '../../services/app_services.dart';
import '../../utils/admin_layout.dart';
import '../../utils/field_zone_layout.dart';
import '../../utils/formation_display.dart';
import '../../utils/formation_layout_grid.dart';
import '../../widgets/common_widgets.dart';

/// 포메이션 필드 10명 레이아웃 편집 (패널 3×2 스냅).
class AdminFormationLayoutPage extends StatefulWidget {
  const AdminFormationLayoutPage({
    super.key,
    required this.services,
    required this.formationId,
  });

  final AppServices services;
  final String formationId;

  @override
  State<AdminFormationLayoutPage> createState() =>
      _AdminFormationLayoutPageState();
}

class _AdminFormationLayoutPageState extends State<AdminFormationLayoutPage> {
  Formation? _formation;
  List<OutfieldLayoutPoint> _layout = const [];
  bool _loading = true;
  bool _saving = false;
  String? _error;
  int? _draggingIndex;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final item =
          await widget.services.formationService.fetchById(widget.formationId);
      if (!mounted) return;
      if (item == null) {
        setState(() {
          _error = '포메이션을 찾을 수 없습니다.';
          _loading = false;
        });
        return;
      }
      setState(() {
        _formation = item;
        _layout = item.resolvedLayoutOutfield();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final formation = _formation;
    if (formation == null || _saving) return;
    setState(() => _saving = true);
    try {
      final updated = await widget.services.formationService.update(
        formation.copyWith(layoutOutfield: List.of(_layout)),
      );
      if (!mounted) return;
      setState(() {
        _formation = updated;
        _layout = updated.resolvedLayoutOutfield();
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('레이아웃이 저장되었습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    }
  }

  void _resetToSlotDefaults() {
    final formation = _formation;
    if (formation == null) return;
    setState(() {
      _layout = FormationLayoutGrid.defaultFromFormationName(formation.name);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: LoadingView());
    }
    if (_error != null || _formation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('포메이션 수정')),
        body: ErrorView(message: _error ?? '오류', onRetry: _load),
      );
    }

    final formation = _formation!;
    final display = FormationDisplay(formation);
    final compact = AdminLayout.isCompact(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${display.name} 레이아웃'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _resetToSlotDefaults,
            child: const Text('슬롯 기본 위치'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_saving ? '저장 중…' : '저장'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(compact ? 12 : 20),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FormationMetaHeader(formation: formation),
                  const SizedBox(height: 12),
                  Expanded(child: _buildEditor()),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 280,
                    child: _FormationMetaHeader(formation: formation),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildEditor()),
                ],
              ),
      ),
    );
  }

  Widget _buildEditor() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              '필드 선수 10명 — 원을 드래그하면 포지션 패널·격자(3×2)에 스냅됩니다. GK는 고정.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _FormationLayoutBoard(
                layout: _layout,
                draggingIndex: _draggingIndex,
                onDragStart: (i) => setState(() => _draggingIndex = i),
                onDragEnd: () => setState(() => _draggingIndex = null),
                onMove: (index, point) {
                  setState(() {
                    final next = List<OutfieldLayoutPoint>.from(_layout);
                    next[index] = point;
                    _layout = next;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormationMetaHeader extends StatelessWidget {
  const _FormationMetaHeader({required this.formation});

  final Formation formation;

  @override
  Widget build(BuildContext context) {
    final display = FormationDisplay(formation);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              display.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            _meta('ID', formation.id),
            _meta('타입', formation.formationType ?? '-'),
            _meta(
              '점유 / 공격 / 안정',
              '${formation.possession} / ${formation.attack} / ${formation.stability}',
            ),
            _meta(
              '키포지션',
              formation.keyPositionEntries.isEmpty
                  ? '-'
                  : formation.keyPositionEntries
                      .map((e) => '${e.id}(슬롯 ${e.slot})')
                      .join('\n'),
            ),
            if (formation.comment != null && formation.comment!.isNotEmpty)
              _meta('코멘트', formation.comment!),
            const SizedBox(height: 12),
            Text(
              formation.layoutOutfield == null
                  ? '저장된 레이아웃 없음 → 알고리즘 백필 표시 중'
                  : 'DB 레이아웃 로드됨',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

class _FormationLayoutBoard extends StatelessWidget {
  const _FormationLayoutBoard({
    required this.layout,
    required this.draggingIndex,
    required this.onDragStart,
    required this.onDragEnd,
    required this.onMove,
  });

  final List<OutfieldLayoutPoint> layout;
  final int? draggingIndex;
  final ValueChanged<int> onDragStart;
  final VoidCallback onDragEnd;
  final void Function(int index, OutfieldLayoutPoint point) onMove;

  static const _tokenSize = 36.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        // 팀편성 시너지 패널과 동일한 기하
        final panels = FieldZoneLayout.zoneRects(size);
        final centers = [
          for (final p in layout)
            FormationLayoutGrid.cellCenter(
              panels[p.slot] ?? Rect.zero,
              p.cell,
            ),
        ];

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // 패널 + 격자
            for (final entry in panels.entries)
              Positioned.fromRect(
                rect: entry.value,
                child: _PositionPanel(
                  slot: entry.key,
                  thickBorder: entry.key != 13,
                  showGrid: entry.key != 13,
                  dimmed: entry.key == 13,
                ),
              ),
            // 토큰 1~10
            for (var i = 0; i < centers.length && i < 10; i++)
              Positioned(
                left: centers[i].dx - _tokenSize / 2,
                top: centers[i].dy - _tokenSize / 2,
                width: _tokenSize,
                height: _tokenSize,
                child: _DraggableToken(
                  number: i + 1,
                  elevating: draggingIndex == i,
                  onDragStart: () => onDragStart(i),
                  onDragEnd: onDragEnd,
                  onDrag: (global) {
                    final box = context.findRenderObject() as RenderBox?;
                    if (box == null) return;
                    final local = box.globalToLocal(global);
                    final snapped =
                        FormationLayoutGrid.snapToCell(local, panels);
                    onMove(i, snapped);
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PositionPanel extends StatelessWidget {
  const _PositionPanel({
    required this.slot,
    required this.thickBorder,
    required this.showGrid,
    this.dimmed = false,
  });

  final int slot;
  final bool thickBorder;
  final bool showGrid;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final label = FormationLayoutGrid.labelFor(slot);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dimmed
            ? const Color(0xFF14532D).withValues(alpha: 0.45)
            : const Color(0xFF166534),
        border: Border.all(
          color: Colors.white,
          width: thickBorder ? 3 : 1.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          if (showGrid)
            Positioned.fill(
              child: CustomPaint(painter: _SubcellGridPainter()),
            ),
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: dimmed ? 0.5 : 0.9),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubcellGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;
    final w = size.width / 3;
    final h = size.height / 2;
    canvas.drawLine(Offset(w, 0), Offset(w, size.height), paint);
    canvas.drawLine(Offset(w * 2, 0), Offset(w * 2, size.height), paint);
    canvas.drawLine(Offset(0, h), Offset(size.width, h), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DraggableToken extends StatelessWidget {
  const _DraggableToken({
    required this.number,
    required this.elevating,
    required this.onDragStart,
    required this.onDragEnd,
    required this.onDrag,
  });

  final int number;
  final bool elevating;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;
  final ValueChanged<Offset> onDrag;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => onDragStart(),
      onPanUpdate: (d) => onDrag(d.globalPosition),
      onPanEnd: (_) => onDragEnd(),
      onPanCancel: onDragEnd,
      child: AnimatedScale(
        scale: elevating ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: elevating ? const Color(0xFFFACC15) : const Color(0xFFF8FAFC),
            border: Border.all(color: Colors.black87, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: elevating ? 8 : 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
