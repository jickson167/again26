import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../models/coach.dart';
import '../../services/app_services.dart';
import '../../utils/admin_layout.dart';
import '../../utils/coach_portrait.dart';
import '../../utils/coach_portrait_prompt.dart';
import '../../utils/portrait_image_check.dart';
import '../../widgets/common_widgets.dart';

class AdminCoachPortraitGeneratorPage extends StatefulWidget {
  const AdminCoachPortraitGeneratorPage({super.key, required this.services});

  final AppServices services;

  @override
  State<AdminCoachPortraitGeneratorPage> createState() =>
      _AdminCoachPortraitGeneratorPageState();
}

class _AdminCoachPortraitGeneratorPageState
    extends State<AdminCoachPortraitGeneratorPage> {
  static const _maxSelection = 5;

  List<Coach> _coaches = [];
  final Set<String> _selectedIds = {};
  final Map<String, bool?> _portraitExists = {};
  bool _loading = true;
  String? _error;

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
      final coaches = await widget.services.coachService.fetchAll();
      if (!mounted) {
        return;
      }
      setState(() {
        _coaches = coaches;
        _loading = false;
        _selectedIds.removeWhere(
          (id) => !coaches.any((coach) => coach.id == id),
        );
      });
      _refreshPortraitStatus(coaches);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refreshPortraitStatus(List<Coach> coaches) async {
    for (final coach in coaches) {
      _checkPortrait(coach);
    }
  }

  Future<void> _checkPortrait(Coach coach) async {
    final url = CoachPortrait.expectedUrl(coach);
    setState(() => _portraitExists[coach.id] = null);

    final exists = await portraitImageExists(url);
    if (!mounted) {
      return;
    }
    setState(() => _portraitExists[coach.id] = exists);
  }

  List<Coach> get _selectedCoaches {
    final byId = {for (final coach in _coaches) coach.id: coach};
    return _selectedIds
        .map((id) => byId[id])
        .whereType<Coach>()
        .toList(growable: false);
  }

  void _toggleSelection(Coach coach, bool? selected) {
    final shouldSelect = selected ?? false;
    if (shouldSelect) {
      if (_selectedIds.length >= _maxSelection) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('최대 $_maxSelection명까지 선택할 수 있습니다.')),
        );
        return;
      }
      setState(() => _selectedIds.add(coach.id));
      return;
    }
    setState(() => _selectedIds.remove(coach.id));
  }

  Future<void> _selectNextWithoutPortrait() async {
    try {
      final nextList = await widget.services.coachService
          .fetchNextWithoutPortraitUrls(limit: _maxSelection);
      if (!mounted) {
        return;
      }
      if (nextList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('portrait_url이 비어 있는 감독이 없습니다.')),
        );
        return;
      }
      setState(() {
        _selectedIds
          ..clear()
          ..addAll(nextList.map((c) => c.id));
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('조회 실패: $error')));
    }
  }

  Future<void> _copyPrompt() async {
    final prompt = CoachPortraitPrompt.buildBatchPrompt(_selectedCoaches);
    if (prompt.isEmpty) {
      return;
    }
    try {
      await Clipboard.setData(ClipboardData(text: prompt));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프롬프트 복사에 실패했습니다. 다시 시도해 주세요.')),
      );
      return;
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('프롬프트를 클립보드에 복사했습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    final prompt = CoachPortraitPrompt.buildBatchPrompt(_selectedCoaches);

    final compact = AdminLayout.isCompact(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('감독 이미지 생성'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          if (compact) ...[
            IconButton(
              tooltip: '다음 미생성',
              onPressed: _loading ? null : _selectNextWithoutPortrait,
              icon: const Icon(Icons.skip_next),
            ),
            IconButton(
              tooltip: '프롬프트 복사',
              onPressed: prompt.isEmpty ? null : _copyPrompt,
              icon: const Icon(Icons.copy),
            ),
            IconButton(
              tooltip: '새로고침',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ] else ...[
            TextButton.icon(
              onPressed: _loading ? null : _selectNextWithoutPortrait,
              icon: const Icon(Icons.skip_next),
              label: const Text('다음 미생성'),
            ),
            IconButton(
              tooltip: '새로고침',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
            TextButton.icon(
              onPressed: () => context.go('/admin'),
              icon: const Icon(Icons.sports),
              label: const Text('감독 목록'),
            ),
          ],
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : LayoutBuilder(
              builder: (context, constraints) {
                final stacked =
                    constraints.maxWidth < AdminLayout.stackedBreakpoint;
                final listPane = _CoachListPane(
                  coaches: _coaches,
                  selectedIds: _selectedIds,
                  portraitExists: _portraitExists,
                  maxSelection: _maxSelection,
                  onToggle: _toggleSelection,
                  onRecheck: _checkPortrait,
                );
                final promptPane = _PromptPane(
                  prompt: prompt,
                  selectedCount: _selectedCoaches.length,
                  maxSelection: _maxSelection,
                  onCopy: _copyPrompt,
                );

                if (stacked) {
                  return Column(
                    children: [
                      Expanded(flex: 3, child: listPane),
                      const Divider(height: 1),
                      Expanded(flex: 2, child: promptPane),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 5, child: listPane),
                    const VerticalDivider(width: 1),
                    Expanded(flex: 4, child: promptPane),
                  ],
                );
              },
            ),
    );
  }
}

class _CoachListPane extends StatelessWidget {
  const _CoachListPane({
    required this.coaches,
    required this.selectedIds,
    required this.portraitExists,
    required this.maxSelection,
    required this.onToggle,
    required this.onRecheck,
  });

  final List<Coach> coaches;
  final Set<String> selectedIds;
  final Map<String, bool?> portraitExists;
  final int maxSelection;
  final void Function(Coach coach, bool? selected) onToggle;
  final Future<void> Function(Coach coach) onRecheck;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '감독 선택 (최대 $maxSelection명 · 5명씩 ChatGPT 수동 생성)',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '선택한 감독마다 PNG 1장 = ${CoachPortraitPath.storageDir}/{id}.png (투명 배경). '
                '「다음 미생성」으로 portrait_url 비어 있는 감독 최대 $maxSelection명 자동 선택.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: coaches.isEmpty
              ? Center(
                  child: Text(
                    '감독이 없습니다.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                )
              : ListView.separated(
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  itemCount: coaches.length,
                  itemBuilder: (context, index) {
                    final coach = coaches[index];
                    final selected = selectedIds.contains(coach.id);
                    final exists = portraitExists[coach.id];

                    return ListTile(
                      leading: Checkbox(
                        value: selected,
                        onChanged: (v) => onToggle(coach, v),
                      ),
                      title: Text(coach.name),
                      subtitle: Text(
                        '${coach.nationality ?? '-'} / ${coach.age ?? '-'}세 / ${coach.coachType} / Rank ${coach.effectiveRank}',
                      ),
                      trailing: SizedBox(
                        width: 120,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (exists == null)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else if (exists)
                              const Icon(Icons.image, color: Colors.green)
                            else
                              const Icon(Icons.image_not_supported,
                                  color: Colors.orange),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 18),
                              onPressed: () => onRecheck(coach),
                              tooltip: '이미지 확인 재시도',
                              padding: EdgeInsets.zero,
                              constraints:
                                  const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _PromptPane extends StatelessWidget {
  const _PromptPane({
    required this.prompt,
    required this.selectedCount,
    required this.maxSelection,
    required this.onCopy,
  });

  final String prompt;
  final int selectedCount;
  final int maxSelection;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ChatGPT 프롬프트 ($selectedCount / $maxSelection명)',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                prompt.isEmpty
                    ? '감독을 선택하면 프롬프트가 생성됩니다.'
                    : prompt,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: prompt.isEmpty ? null : onCopy,
            icon: const Icon(Icons.copy),
            label: const Text('프롬프트 복사'),
          ),
        ),
      ],
    );
  }
}
