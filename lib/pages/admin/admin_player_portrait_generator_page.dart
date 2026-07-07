import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../models/player.dart';
import '../../services/app_services.dart';
import '../../utils/admin_layout.dart';
import '../../utils/player_portrait.dart';
import '../../utils/player_portrait_prompt.dart';
import '../../utils/portrait_image_check.dart';
import '../../widgets/common_widgets.dart';

class AdminPlayerPortraitGeneratorPage extends StatefulWidget {
  const AdminPlayerPortraitGeneratorPage({super.key, required this.services});

  final AppServices services;

  @override
  State<AdminPlayerPortraitGeneratorPage> createState() =>
      _AdminPlayerPortraitGeneratorPageState();
}

class _AdminPlayerPortraitGeneratorPageState
    extends State<AdminPlayerPortraitGeneratorPage> {
  static const _maxSelection = 5;

  List<Player> _players = [];
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
      final players = await widget.services.playerService.fetchAll();
      if (!mounted) {
        return;
      }
      setState(() {
        _players = players;
        _loading = false;
        _selectedIds.removeWhere(
          (id) => !players.any((player) => player.id == id),
        );
      });
      _refreshPortraitStatus(players);
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

  Future<void> _refreshPortraitStatus(List<Player> players) async {
    for (final player in players) {
      _checkPortrait(player);
    }
  }

  Future<void> _checkPortrait(Player player) async {
    final url = PlayerPortrait.expectedUrl(player);
    setState(() => _portraitExists[player.id] = null);

    final exists = await portraitImageExists(url);
    if (!mounted) {
      return;
    }
    setState(() => _portraitExists[player.id] = exists);
  }
  List<Player> get _selectedPlayers {
    final byId = {for (final player in _players) player.id: player};
    return _selectedIds
        .map((id) => byId[id])
        .whereType<Player>()
        .toList(growable: false);
  }

  void _toggleSelection(Player player, bool? selected) {
    final shouldSelect = selected ?? false;
    if (shouldSelect) {
      if (_selectedIds.length >= _maxSelection) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('최대 $_maxSelection명까지 선택할 수 있습니다.')),
        );
        return;
      }
      setState(() => _selectedIds.add(player.id));
      return;
    }
    setState(() => _selectedIds.remove(player.id));
  }

  Future<void> _selectNextWithoutPortrait() async {
    try {
      final nextList = await widget.services.playerService
          .fetchNextWithoutPortraitUrls(limit: _maxSelection);
      if (!mounted) {
        return;
      }
      if (nextList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('portrait_url이 비어 있는 선수가 없습니다.')),
        );
        return;
      }
      setState(() {
        _selectedIds
          ..clear()
          ..addAll(nextList.map((p) => p.id));
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('조회 실패: $error')),
      );
    }
  }

  Future<void> _copyPrompt() async {
    final prompt = PlayerPortraitPrompt.buildBatchPrompt(_selectedPlayers);
    if (prompt.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: prompt));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('프롬프트를 클립보드에 복사했습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prompt = PlayerPortraitPrompt.buildBatchPrompt(_selectedPlayers);

    final compact = AdminLayout.isCompact(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('선수 이미지 생성'),
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
              icon: const Icon(Icons.person),
              label: const Text('선수 목록'),
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
                    final listPane = _PlayerListPane(
                      players: _players,
                      selectedIds: _selectedIds,
                      portraitExists: _portraitExists,
                      maxSelection: _maxSelection,
                      onToggle: _toggleSelection,
                      onRecheck: _checkPortrait,
                    );
                    final promptPane = _PromptPane(
                      prompt: prompt,
                      selectedCount: _selectedPlayers.length,
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

class _PlayerListPane extends StatelessWidget {
  const _PlayerListPane({
    required this.players,
    required this.selectedIds,
    required this.portraitExists,
    required this.maxSelection,
    required this.onToggle,
    required this.onRecheck,
  });

  final List<Player> players;
  final Set<String> selectedIds;
  final Map<String, bool?> portraitExists;
  final int maxSelection;
  final void Function(Player player, bool? selected) onToggle;
  final Future<void> Function(Player player) onRecheck;

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
                '선수 선택 (최대 $maxSelection명 · 5명씩 ChatGPT 수동 생성)',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '선택한 선수마다 PNG 1장 = ${PlayerPortraitPath.storageDir}/{id}.png (투명 배경). '
                '「다음 미생성」으로 portrait_url 비어 있는 선수 최대 5명 자동 선택.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: players.isEmpty
              ? const Center(child: Text('등록된 선수가 없습니다.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(8, 0, 16, 16),
                  itemCount: players.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final player = players[index];
                    final selected = selectedIds.contains(player.id);
                    final exists = portraitExists[player.id];

                    return ListTile(
                      leading: Checkbox(
                        value: selected,
                        onChanged: (value) => onToggle(player, value),
                      ),
                      title: Text('${player.id} · ${player.name}'),
                      subtitle: Text(
                        [
                          player.nationality ?? '-',
                          player.ageStage ?? '-',
                          player.displaySeedNames.join('; '),
                          player.detailPosition ?? player.position.label,
                        ].join(' · '),
                      ),
                      trailing: _PortraitStatusBadge(
                        exists: exists,
                        onRecheck: () => onRecheck(player),
                        compact: AdminLayout.isCompact(context),
                      ),
                      onTap: () => onToggle(player, !selected),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _PortraitStatusBadge extends StatelessWidget {
  const _PortraitStatusBadge({
    required this.exists,
    required this.onRecheck,
    this.compact = false,
  });

  final bool? exists;
  final VoidCallback onRecheck;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (exists == null) {
      return const SizedBox(
        width: 72,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final hasImage = exists!;
    if (compact) {
      return Icon(
        hasImage ? Icons.check_circle : Icons.hide_image_outlined,
        size: 20,
        color: hasImage ? Colors.green : Colors.grey,
      );
    }

    return SizedBox(
      width: 88,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            hasImage ? Icons.check_circle : Icons.hide_image_outlined,
            size: 18,
            color: hasImage ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            hasImage ? '있음' : '없음',
            style: TextStyle(
              fontSize: 13,
              color: hasImage ? Colors.green.shade700 : Colors.grey.shade600,
            ),
          ),
          IconButton(
            tooltip: '이미지 확인 새로고침',
            visualDensity: VisualDensity.compact,
            onPressed: onRecheck,
            icon: const Icon(Icons.refresh, size: 18),
          ),
        ],
      ),
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
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '생성 프롬프트',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              FilledButton.icon(
                onPressed: prompt.isEmpty ? null : onCopy,
                icon: const Icon(Icons.copy),
                label: const Text('프롬프트 복사'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            selectedCount == 0
                ? '선수를 선택하거나 「다음 미생성」을 누르세요. (최대 $maxSelection명)'
                : '선택 $selectedCount명 · 프롬프트 복사 → ChatGPT → PNG 각각 web/player_images/{id}.png 저장',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor),
              ),
              child: prompt.isEmpty
                  ? const Center(
                      child: Text('선수를 1~5명 선택하세요.'),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        prompt,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
