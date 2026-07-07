import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/coach.dart';
import '../../models/formation.dart';
import '../../models/key_position.dart';
import '../../models/player.dart';
import '../../services/app_services.dart';
import '../../services/coach_csv_service.dart';
import '../../services/csv_service.dart';
import '../../services/formation_csv_service.dart';
import '../../services/key_position_csv_service.dart';
import '../../utils/admin_layout.dart';
import '../../widgets/admin_row_actions.dart';
import '../../widgets/csv_drop_import_zone.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/seed_name_chips.dart';
import '../../utils/formation_display.dart';
import '../../widgets/coach_detail_card.dart';
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
    _tabController = TabController(length: 4, vsync: this);
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
        actions: [
          IconButton(
            tooltip: '국기 매핑',
            icon: const Icon(Icons.flag_outlined),
            onPressed: () => context.go('/admin/flag-nation-mapper'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: '선수'),
            Tab(icon: Icon(Icons.sports), text: '감독'),
            Tab(icon: Icon(Icons.grid_view), text: '포메이션'),
            Tab(icon: Icon(Icons.star), text: '키포지션'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AdminPlayersTab(services: widget.services),
          AdminCoachesTab(services: widget.services),
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
    Player detail = player;
    try {
      detail = await widget.services.playerService.fetchById(player.id) ?? player;
    } catch (_) {
      detail = player;
    }
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: AdminLayout.dialogInsets(context),
        child: ConstrainedBox(
          constraints: AdminLayout.dialogConstraints(context),
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
                    player: detail,
                    keyPositionsById: _keyPositions,
                    editableComment: true,
                    onSaveComment: (comment) async {
                      final updated = detail.copyWith(comment: comment);
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
          onGenerator: () => context.go('/admin/player-generator'),
          onSecondaryGenerator: () =>
              context.go('/admin/player-portrait-generator'),
          secondaryGeneratorLabel: '선수 이미지 생성',
        ),
        _RankCountSummary(
          entityLabel: '선수',
          rankCounts: _summarizeRanks(_players.map((player) => player.rank)),
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
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${player.detailPosition ?? player.position.label} · 랭크 ${player.rank ?? '-'}',
                          ),
                          const SizedBox(height: 4),
                          SeedNameChips(
                            seedNames: player.displaySeedNames,
                            dense: true,
                          ),
                        ],
                      ),
                      trailing: AdminRowActions(
                        actions: [
                          AdminRowAction(
                            label: '자세히',
                            icon: Icons.search,
                            onPressed: () => _showDetail(player),
                          ),
                          AdminRowAction(
                            label: '수정',
                            icon: Icons.edit,
                            onPressed: () =>
                                context.go('/admin/${player.id}/edit'),
                          ),
                          AdminRowAction(
                            label: '삭제',
                            icon: Icons.delete_outline,
                            isDestructive: true,
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

class AdminCoachesTab extends StatefulWidget {
  const AdminCoachesTab({super.key, required this.services});

  final AppServices services;

  @override
  State<AdminCoachesTab> createState() => _AdminCoachesTabState();
}

class _AdminCoachesTabState extends State<AdminCoachesTab> {
  final _csvService = CoachCsvService();
  List<Coach> _coaches = [];
  Map<String, Formation> _formations = {};
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
        widget.services.coachService.fetchAll(),
        widget.services.formationService.fetchAll(),
      ]);
      if (!mounted) {
        return;
      }
      final formations = results[1] as List<Formation>;
      setState(() {
        _coaches = results[0] as List<Coach>;
        _formations = {for (final f in formations) f.id: f};
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

  Future<void> _showDetail(Coach coach) async {
    final fresh = await widget.services.coachService.fetchById(coach.id) ?? coach;
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: AdminLayout.dialogInsets(context),
        child: ConstrainedBox(
          constraints: AdminLayout.dialogConstraints(context),
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
                  child: CoachDetailCard(
                    coach: fresh,
                    formationsById: _formations,
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
      final coaches = _csvService.parseCsv(content);
      if (coaches.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('가져올 감독 데이터가 없습니다.')),
          );
        }
        return;
      }
      CoachCsvService.validateForDatabase(coaches);
      await widget.services.coachService.upsertMany(coaches);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${coaches.length}명 감독 가져옴')),
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
    _csvService.downloadCsv(_csvService.exportCoaches(_coaches));
  }

  Future<void> _deleteCoach(Coach coach) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('감독 삭제'),
        content: Text('${coach.name} 감독을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await widget.services.coachService.delete(coach.id);
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
          onAdd: () => context.go('/admin/coaches/new'),
          addLabel: '감독 추가',
          onGenerator: () => context.go('/admin/coach-generator'),
          generatorLabel: '감독 생성기',
        ),
        _RankCountSummary(
          entityLabel: '감독',
          rankCounts: _summarizeRanks(_coaches.map((coach) => coach.effectiveRank)),
        ),
        CsvDropImportZone(
          label: '감독 CSV 업로드',
          busy: _importing,
          onImport: _importFromContent,
        ),
        Expanded(
          child: _coaches.isEmpty
              ? const Center(child: Text('등록된 감독이 없습니다. CSV를 가져오세요.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _coaches.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final coach = _coaches[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text('${coach.effectiveRank}')),
                      title: Text(coach.name),
                      subtitle: Text(
                        '${coach.coachType} · ${coach.age != null ? '${coach.age}세 · ' : ''}통솔 ${coach.baseLeadership} · ${coach.abilityName}',
                      ),
                      trailing: AdminRowActions(
                        actions: [
                          AdminRowAction(
                            label: '자세히',
                            icon: Icons.search,
                            onPressed: () => _showDetail(coach),
                          ),
                          AdminRowAction(
                            label: '수정',
                            icon: Icons.edit,
                            onPressed: () =>
                                context.go('/admin/coaches/${coach.id}/edit'),
                          ),
                          AdminRowAction(
                            label: '삭제',
                            icon: Icons.delete_outline,
                            isDestructive: true,
                            onPressed: () => _deleteCoach(coach),
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
      var formations = results[0] as List<Formation>;
      if (formations.any(FormationDisplay.isCorruptRecord)) {
        await widget.services.formationService.deleteCorruptRecords();
        formations = await widget.services.formationService.fetchAll();
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _items = formations;
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
    final fresh = await widget.services.formationService.fetchById(item.id) ?? item;
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: AdminLayout.dialogInsets(context),
        child: ConstrainedBox(
          constraints: AdminLayout.dialogConstraints(context),
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
                    formation: fresh,
                    keyPositionsById: _keyPositions,
                    editableComment: true,
                    onSaveComment: (comment) async {
                      await widget.services.formationService.update(
                        fresh.copyWith(comment: comment),
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
      final removed = await widget.services.formationService.deleteCorruptRecords();
      await widget.services.formationService.upsertMany(items);
      if (mounted) {
        final suffix = removed > 0 ? ' (깨진 데이터 $removed개 제거)' : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${items.length}개 포메이션 가져옴$suffix')),
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
                      leading: CircleAvatar(
                        child: Text(
                          item.formationType?.toUpperCase() ?? display.name.split('-').first,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      title: Text(display.name),
                      subtitle: Text(
                        '${item.formationType ?? '-'} · 점유 ${item.possession} · 공격 ${item.attack} · 안정 ${item.stability}',
                      ),
                      trailing: AdminRowActions(
                        actions: [
                          AdminRowAction(
                            label: '자세히',
                            icon: Icons.search,
                            onPressed: () => _showDetail(item),
                          ),
                          AdminRowAction(
                            label: '삭제',
                            icon: Icons.delete_outline,
                            isDestructive: true,
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
        insetPadding: AdminLayout.dialogInsets(context),
        child: ConstrainedBox(
          constraints: AdminLayout.dialogConstraints(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
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
                      trailing: AdminRowActions(
                        actions: [
                          AdminRowAction(
                            label: '자세히',
                            icon: Icons.search,
                            onPressed: () => _showDetail(item),
                          ),
                          AdminRowAction(
                            label: '삭제',
                            icon: Icons.delete_outline,
                            isDestructive: true,
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

({Map<int, int> byRank, int unranked}) _summarizeRanks(Iterable<int?> ranks) {
  final byRank = {for (var rank = 1; rank <= 5; rank++) rank: 0};
  var unranked = 0;
  for (final rank in ranks) {
    if (rank == null || rank < 1 || rank > 5) {
      unranked++;
    } else {
      byRank[rank] = byRank[rank]! + 1;
    }
  }
  return (byRank: byRank, unranked: unranked);
}

class _RankCountSummary extends StatelessWidget {
  const _RankCountSummary({
    required this.entityLabel,
    required this.rankCounts,
  });

  final String entityLabel;
  final ({Map<int, int> byRank, int unranked}) rankCounts;

  @override
  Widget build(BuildContext context) {
    final total = rankCounts.byRank.values.fold<int>(0, (sum, count) => sum + count) +
        rankCounts.unranked;
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '$entityLabel 총 $total명',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            for (var rank = 1; rank <= 5; rank++)
              _RankCountChip(rank: rank, count: rankCounts.byRank[rank] ?? 0),
            if (rankCounts.unranked > 0)
              Text(
                '미지정 ${rankCounts.unranked}명',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
              ),
          ],
        ),
      ),
    );
  }
}

class _RankCountChip extends StatelessWidget {
  const _RankCountChip({required this.rank, required this.count});

  final int rank;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(
            rank,
            (_) => const Icon(Icons.star, size: 12, color: Colors.amber),
          ),
          const SizedBox(width: 4),
          Text('$count명', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _AdminToolbar extends StatelessWidget {
  const _AdminToolbar({
    required this.onExport,
    this.onAdd,
    this.addLabel = '추가',
    this.onGenerator,
    this.generatorLabel = '선수 생성기',
    this.onSecondaryGenerator,
    this.secondaryGeneratorLabel = '선수 이미지 생성',
  });

  final VoidCallback onExport;
  final VoidCallback? onAdd;
  final String addLabel;
  final VoidCallback? onGenerator;
  final String generatorLabel;
  final VoidCallback? onSecondaryGenerator;
  final String secondaryGeneratorLabel;

  @override
  Widget build(BuildContext context) {
    final compact = AdminLayout.isCompact(context);

    return Material(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (compact)
              IconButton.filledTonal(
                tooltip: 'CSV 내보내기',
                onPressed: onExport,
                icon: const Icon(Icons.download),
              )
            else
              OutlinedButton.icon(
                onPressed: onExport,
                icon: const Icon(Icons.download),
                label: const Text('CSV 내보내기'),
              ),
            if (onGenerator != null)
              compact
                  ? IconButton.filledTonal(
                      tooltip: generatorLabel,
                      onPressed: onGenerator,
                      icon: const Icon(Icons.construction),
                    )
                  : OutlinedButton.icon(
                      onPressed: onGenerator,
                      icon: const Icon(Icons.construction),
                      label: Text(generatorLabel),
                    ),
            if (onSecondaryGenerator != null)
              compact
                  ? IconButton.filledTonal(
                      tooltip: secondaryGeneratorLabel,
                      onPressed: onSecondaryGenerator,
                      icon: const Icon(Icons.image),
                    )
                  : OutlinedButton.icon(
                      onPressed: onSecondaryGenerator,
                      icon: const Icon(Icons.image),
                      label: Text(secondaryGeneratorLabel),
                    ),
            if (onAdd != null)
              compact
                  ? IconButton.filled(
                      tooltip: addLabel,
                      onPressed: onAdd,
                      icon: const Icon(Icons.add),
                    )
                  : OutlinedButton.icon(
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
