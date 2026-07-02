import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/formation.dart';
import '../../models/key_position.dart';
import '../../models/player.dart';
import '../../services/app_services.dart';
import '../../services/csv_service.dart';
import '../../services/formation_csv_service.dart';
import '../../services/key_position_csv_service.dart';
import '../../widgets/csv_drop_import_zone.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/formation_display.dart';
import '../../widgets/formation_detail_card.dart';
import '../../widgets/player_detail_card.dart';

class AdminHubPage extends StatefulWidget {
  const AdminHubPage({super.key, required this.services});

  final AppServices services;

  @override
  State<AdminHubPage> createState() => _AdminHubPageState();
}

class _AdminHubPageState extends State<AdminHubPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('매니저 데이터 관리'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => context.go('/'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: '선수'),
            Tab(icon: Icon(Icons.grid_view), text: '포메이션'),
            Tab(icon: Icon(Icons.star), text: '키포지션'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AdminPlayersTab(services: widget.services),
          AdminFormationsTab(services: widget.services),
          AdminKeyPositionsTab(services: widget.services),
        ],
      ),
    );
  }
}

class AdminPlayersTab extends StatefulWidget {
  const AdminPlayersTab({super.key, required this.services});

  final AppServices services;

  @override
  State<AdminPlayersTab> createState() => _AdminPlayersTabState();
}

class _AdminPlayersTabState extends State<AdminPlayersTab> {
  final _csvService = CsvService();
  List<Player> _players = [];
  Map<String, KeyPosition> _keyPositions = {};
  bool _loading = true;
  bool _importing = false;
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
      final results = await Future.wait([
        widget.services.playerService.fetchAll(),
        widget.services.keyPositionService.fetchAll(),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _players = results[0] as List<Player>;
        _keyPositions = {
          for (final kp in results[1] as List<KeyPosition>) kp.id: kp,
        };
        _loading = false;
      });
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

  Future<void> _showDetail(Player player) async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960, maxHeight: 820),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: PlayerDetailCard(
                    player: player,
                    keyPositionsById: _keyPositions,
                    editableComment: true,
                    onSaveComment: (comment) async {
                      final updated = player.copyWith(comment: comment);
                      await widget.services.playerService.update(updated);
                      await _load();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deletePlayer(Player player) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('선수 삭제'),
        content: Text('${player.name} 선수를 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await widget.services.playerService.delete(player.id);
    await _load();
  }

  Future<void> _importFromContent(String content) async {
    setState(() => _importing = true);
    try {
      final players = _csvService.parseCsv(content);
      if (players.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('가져올 선수 데이터가 없습니다.')),
          );
        }
        return;
      }
      await widget.services.playerService.upsertMany(players);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${players.length}명 가져옴')),
        );
      }
      await _load();
    } finally {
      if (mounted) {
        setState(() => _importing = false);
      }
    }
  }

  void _exportCsv() {
    _csvService.downloadCsv(_csvService.exportPlayers(_players));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LoadingView();
    }
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }

    return Column(
      children: [
        _AdminToolbar(
          onExport: _exportCsv,
          onAdd: () => context.go('/admin/new'),
          addLabel: '선수 추가',
        ),
        CsvDropImportZone(
          label: '선수 CSV 업로드',
          busy: _importing,
          onImport: _importFromContent,
        ),
        Expanded(
          child: _players.isEmpty
              ? const Center(child: Text('등록된 선수가 없습니다.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _players.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final player = _players[index];
                    return ListTile(
                      leading: PlayerAvatar(
                        name: player.name,
                        portraitUrl: player.portraitUrl,
                      ),
                      title: Text(player.name),
                      subtitle: Text(
                        '${player.detailPosition ?? player.position.label} · 랭크 ${player.rank ?? '-'}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: '자세히 보기',
                            icon: const Icon(Icons.search),
                            onPressed: () => _showDetail(player),
                          ),
                          IconButton(
                            tooltip: '수정',
                            icon: const Icon(Icons.edit),
                            onPressed: () => context.go('/admin/${player.id}/edit'),
                          ),
                          IconButton(
                            tooltip: '삭제',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deletePlayer(player),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class AdminFormationsTab extends StatefulWidget {
  const AdminFormationsTab({super.key, required this.services});

  final AppServices services;

  @override
  State<AdminFormationsTab> createState() => _AdminFormationsTabState();
}

class _AdminFormationsTabState extends State<AdminFormationsTab> {
  final _csvService = FormationCsvService();
  List<Formation> _items = [];
  Map<String, KeyPosition> _keyPositions = {};
  bool _loading = true;
  bool _importing = false;
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
      final results = await Future.wait([
        widget.services.formationService.fetchAll(),
        widget.services.keyPositionService.fetchAll(),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _items = results[0] as List<Formation>;
        _keyPositions = {
          for (final kp in results[1] as List<KeyPosition>) kp.id: kp,
        };
        _loading = false;
      });
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

  Future<void> _showDetail(Formation item) async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 820),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: FormationDetailCard(
                    formation: item,
                    keyPositionsById: _keyPositions,
                    editableComment: true,
                    onSaveComment: (comment) async {
                      await widget.services.formationService.update(
                        item.copyWith(comment: comment),
                      );
                      await _load();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _importFromContent(String content) async {
    setState(() => _importing = true);
    try {
      final items = _csvService.parseCsv(content);
      if (items.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('가져올 포메이션 데이터가 없습니다.')),
          );
        }
        return;
      }
      FormationCsvService.validateForDatabase(items);
      await widget.services.formationService.upsertMany(items);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${items.length}개 포메이션 가져옴')),
        );
      }
      await _load();
    } on FormatException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _importing = false);
      }
    }
  }

  void _exportCsv() {
    _csvService.downloadCsv(_csvService.exportFormations(_items));
  }

  Future<void> _delete(Formation item) async {
    await widget.services.formationService.delete(item.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LoadingView();
    }
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }

    return Column(
      children: [
        _AdminToolbar(
          onExport: _exportCsv,
        ),
        CsvDropImportZone(
          label: '포메이션 CSV 업로드',
          busy: _importing,
          onImport: _importFromContent,
        ),
        Expanded(
          child: _items.isEmpty
              ? const Center(child: Text('등록된 포메이션이 없습니다. CSV를 가져오세요.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final display = FormationDisplay(item);
                    return ListTile(
                      leading: CircleAvatar(child: Text(display.name.split('-').first)),
                      title: Text(display.name),
                      subtitle: Text(display.tacticalType),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: '자세히 보기',
                            icon: const Icon(Icons.search),
                            onPressed: () => _showDetail(item),
                          ),
                          IconButton(
                            tooltip: '삭제',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _delete(item),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class AdminKeyPositionsTab extends StatefulWidget {
  const AdminKeyPositionsTab({super.key, required this.services});

  final AppServices services;

  @override
  State<AdminKeyPositionsTab> createState() => _AdminKeyPositionsTabState();
}

class _AdminKeyPositionsTabState extends State<AdminKeyPositionsTab> {
  final _csvService = KeyPositionCsvService();
  List<KeyPosition> _items = [];
  bool _loading = true;
  bool _importing = false;
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
      final items = await widget.services.keyPositionService.fetchAll();
      if (!mounted) {
        return;
      }
      setState(() {
        _items = items;
        _loading = false;
      });
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

  Future<void> _showDetail(KeyPosition item) async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.name, style: Theme.of(context).textTheme.titleLarge),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                Text('${item.simplePosition.label} · ${item.id}'),
                const SizedBox(height: 8),
                Text('주: ${item.mainStat} / 부: ${item.subStat}'),
                Text('성향: ${item.mentalPref} · ${item.teamPref}'),
                const SizedBox(height: 12),
                Text(item.description ?? '설명 없음'),
                if (item.comment != null && item.comment!.isNotEmpty) ...[
                  const Divider(),
                  Text(item.comment!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _importFromContent(String content) async {
    setState(() => _importing = true);
    try {
      final items = _csvService.parseCsv(content);
      if (items.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('가져올 키포지션 데이터가 없습니다.')),
          );
        }
        return;
      }
      KeyPositionCsvService.validateForDatabase(items);
      await widget.services.keyPositionService.upsertMany(items);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${items.length}개 키포지션 가져옴')),
        );
      }
      await _load();
    } finally {
      if (mounted) {
        setState(() => _importing = false);
      }
    }
  }

  void _exportCsv() {
    _csvService.downloadCsv(_csvService.exportKeyPositions(_items));
  }

  Future<void> _delete(KeyPosition item) async {
    await widget.services.keyPositionService.delete(item.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LoadingView();
    }
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }

    return Column(
      children: [
        _AdminToolbar(
          onExport: _exportCsv,
        ),
        CsvDropImportZone(
          label: '키포지션 CSV 업로드',
          busy: _importing,
          onImport: _importFromContent,
        ),
        Expanded(
          child: _items.isEmpty
              ? const Center(child: Text('등록된 키포지션이 없습니다. CSV를 가져오세요.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text(item.simplePosition.code.toUpperCase())),
                      title: Text(item.name),
                      subtitle: Text('${item.mainStat}/${item.subStat} · ${item.id}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: '자세히 보기',
                            icon: const Icon(Icons.search),
                            onPressed: () => _showDetail(item),
                          ),
                          IconButton(
                            tooltip: '삭제',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _delete(item),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AdminToolbar extends StatelessWidget {
  const _AdminToolbar({
    required this.onExport,
    this.onAdd,
    this.addLabel = '추가',
  });

  final VoidCallback onExport;
  final VoidCallback? onAdd;
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: onExport,
              icon: const Icon(Icons.download),
              label: const Text('CSV 내보내기'),
            ),
            if (onAdd != null)
              OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: Text(addLabel),
              ),
          ],
        ),
      ),
    );
  }
}
