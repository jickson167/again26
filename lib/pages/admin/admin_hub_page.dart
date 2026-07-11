import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/club_emblem.dart';
import '../../models/coach.dart';
import '../../models/formation.dart';
import '../../models/key_position.dart';
import '../../models/player.dart';
import '../../models/player_position.dart';
import '../../models/player_style.dart';
import '../../services/app_services.dart';
import '../../services/coach_csv_service.dart';
import '../../services/csv_service.dart';
import '../../services/formation_csv_service.dart';
import '../../services/key_position_csv_service.dart';
import '../../utils/admin_layout.dart';
import '../../widgets/admin_row_actions.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/player_style_chips.dart';
import '../../widgets/seed_name_chips.dart';
import '../../utils/formation_display.dart';
import '../../widgets/coach_detail_card.dart';
import '../../widgets/formation_detail_card.dart';
import '../../widgets/player_detail_card.dart';
import '../../services/nation_flag_service.dart';
import '../../utils/portrait_data_url.dart';
import '../../utils/portrait_image_check.dart';
import '../../widgets/portrait_drop_avatar.dart';

class AdminHubPage extends StatefulWidget {
  const AdminHubPage({
    super.key,
    required this.services,
    this.initialTab,
    this.coachesRefreshToken,
  });

  final AppServices services;
  final String? initialTab;
  final String? coachesRefreshToken;

  @override
  State<AdminHubPage> createState() => _AdminHubPageState();
}

class _AdminHubPageState extends State<AdminHubPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialTab == 'coach' ? 1 : 0;
    _tabController = TabController(length: 7, vsync: this, initialIndex: initialIndex);
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
            Tab(icon: Icon(Icons.flag), text: '국기이미지'),
            Tab(icon: Icon(Icons.shield), text: '클럽앰블럼'),
            Tab(icon: Icon(Icons.style), text: '선수스타일'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AdminPlayersTab(services: widget.services),
          AdminCoachesTab(
            services: widget.services,
            refreshToken: widget.coachesRefreshToken,
          ),
          AdminFormationsTab(services: widget.services),
          AdminKeyPositionsTab(services: widget.services),
          AdminNationFlagsTab(services: widget.services),
          AdminClubEmblemsTab(services: widget.services),
          AdminPlayerStylesTab(services: widget.services),
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

enum _PlayerSortType {
  id('아이디순'),
  rank('랭크순'),
  nation('나라순'),
  simplePosition('심플포지션순'),
  seed('시드순');

  const _PlayerSortType(this.label);
  final String label;
}

class _AdminPlayersTabState extends State<AdminPlayersTab> {
  final _csvService = CsvService();
  final _listScrollController = ScrollController();
  List<Player> _players = [];
  Map<String, KeyPosition> _keyPositions = {};
  Map<String, PlayerStyle> _stylesById = {};
  Map<String, bool?> _portraitExists = {};
  final Set<String> _portraitUploading = {};
  _PlayerSortType _sortType = _PlayerSortType.id;
  bool _loading = true;
  String? _error;

  List<Player> get _sortedPlayers {
    final list = List<Player>.from(_players);

    int idNumber(Player player) => int.tryParse(player.id) ?? 999999;
    int positionOrder(Player player) {
      return switch (player.position) {
        PlayerPosition.fw => 0,
        PlayerPosition.mf => 1,
        PlayerPosition.df => 2,
        PlayerPosition.gk => 3,
      };
    }

    switch (_sortType) {
      case _PlayerSortType.id:
        list.sort((a, b) => idNumber(a).compareTo(idNumber(b)));
      case _PlayerSortType.rank:
        list.sort((a, b) {
          final ar = a.rank ?? 99;
          final br = b.rank ?? 99;
          final rankCompare = ar.compareTo(br);
          if (rankCompare != 0) {
            return rankCompare;
          }
          return idNumber(a).compareTo(idNumber(b));
        });
      case _PlayerSortType.nation:
        list.sort((a, b) {
          final an = a.nationality?.trim() ?? '';
          final bn = b.nationality?.trim() ?? '';
          if (an.isEmpty && bn.isNotEmpty) {
            return 1;
          }
          if (an.isNotEmpty && bn.isEmpty) {
            return -1;
          }
          final nationCompare = an.compareTo(bn);
          if (nationCompare != 0) {
            return nationCompare;
          }
          return idNumber(a).compareTo(idNumber(b));
        });
      case _PlayerSortType.simplePosition:
        list.sort((a, b) {
          final posCompare = positionOrder(a).compareTo(positionOrder(b));
          if (posCompare != 0) {
            return posCompare;
          }
          return idNumber(a).compareTo(idNumber(b));
        });
      case _PlayerSortType.seed:
        list.sort((a, b) {
          final as = a.displaySeedNames.join(', ');
          final bs = b.displaySeedNames.join(', ');
          final seedCompare = as.compareTo(bs);
          if (seedCompare != 0) {
            return seedCompare;
          }
          return idNumber(a).compareTo(idNumber(b));
        });
    }

    return list;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    super.dispose();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() {
        _error = null;
      });
    }
    try {
      final results = await Future.wait([
        widget.services.playerService.fetchAll(),
        widget.services.keyPositionService.fetchAll(),
        widget.services.playerStyleService.fetchByIdMap(),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _players = results[0] as List<Player>;
        _keyPositions = {
          for (final kp in results[1] as List<KeyPosition>) kp.id: kp,
        };
        _stylesById = results[2] as Map<String, PlayerStyle>;
        final validIds = _players.map((player) => player.id).toSet();
        _portraitExists.removeWhere((id, _) => !validIds.contains(id));
        _loading = false;
      });
      _refreshPlayerPortraitStatus(_players);
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

  Future<void> _refreshPlayerPortraitStatus(List<Player> players) async {
    for (final player in players) {
      _checkPlayerPortrait(player);
    }
  }

  Future<void> _checkPlayerPortrait(Player player) async {
    final url = player.portraitUrl?.trim();
    if (url == null || url.isEmpty) {
      setState(() => _portraitExists[player.id] = false);
      return;
    }

    setState(() => _portraitExists[player.id] = null);
    final exists = await portraitImageExists(url);
    if (!mounted) {
      return;
    }
    setState(() => _portraitExists[player.id] = exists);
  }

  Future<void> _uploadPlayerPortrait(
    Player player,
    List<int> bytes,
    String fileName,
  ) async {
    if (_portraitUploading.contains(player.id)) {
      return;
    }
    setState(() => _portraitUploading.add(player.id));
    try {
      final dataUrl = portraitDataUrlFromBytes(bytes, fileName);
      final updated = await widget.services.playerService.patch(
        player.id,
        {'portrait_url': dataUrl},
      );
      if (!mounted) {
        return;
      }
      setState(() {
        final index = _players.indexWhere((item) => item.id == player.id);
        if (index >= 0) {
          _players[index] = updated;
        }
      });
      _checkPlayerPortrait(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${player.name} 이미지가 저장되었습니다.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 저장 실패: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _portraitUploading.remove(player.id));
      }
    }
  }

  Future<void> _showDetail(Player player) async {
    Player detail = player;
    try {
      detail =
          await widget.services.playerService.fetchById(player.id) ?? player;
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
                    styleLabels: resolveStyleLabels(
                      styleIds: detail.styleIds,
                      stylesById: _stylesById,
                    ),
                    editableComment: true,
                    onSaveComment: (comment) async {
                      await widget.services.playerService.patch(
                        detail.id,
                        {'comment': comment},
                      );
                      await _load(showLoading: false);
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await widget.services.playerService.delete(player.id);
    await _load();
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

    final rankCounts = _summarizeRanks(_players.map((player) => player.rank));
    final totalCount =
        rankCounts.byRank.values.fold<int>(0, (sum, count) => sum + count) +
        rankCounts.unranked;

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
        Material(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('정렬:'),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 150,
                    child: DropdownButton<_PlayerSortType>(
                      value: _sortType,
                      isExpanded: true,
                      items: _PlayerSortType.values
                          .map(
                            (type) => DropdownMenuItem<_PlayerSortType>(
                              value: type,
                              child: Text(type.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() => _sortType = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '선수 총 $totalCount명',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  for (var rank = 1; rank <= 5; rank++) ...[
                    _RankCountChip(
                      rank: rank,
                      count: rankCounts.byRank[rank] ?? 0,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (rankCounts.unranked > 0)
                    Text(
                      '미지정 ${rankCounts.unranked}명',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: _sortedPlayers.isEmpty
              ? const Center(child: Text('등록된 선수가 없습니다.'))
              : ListView.separated(
                  controller: _listScrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _sortedPlayers.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final player = _sortedPlayers[index];
                    final compact = AdminLayout.isCompact(context);
                    return ListTile(
                      isThreeLine: compact,
                      contentPadding: compact
                          ? const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            )
                          : null,
                      leading: PortraitDropAvatar(
                        name: player.name,
                        portraitUrl: player.portraitUrl,
                        uploading: _portraitUploading.contains(player.id),
                        onImageDropped: (bytes, fileName) =>
                            _uploadPlayerPortrait(player, bytes, fileName),
                      ),
                      title: _AdminListTitle(
                        name: player.name,
                        meta: [
                          if (player.fakeName != null &&
                              player.fakeName!.isNotEmpty)
                            Text(
                              '가명: ${player.fakeName}',
                              style: _adminListMetaStyle,
                            ),
                          if (player.peakAge != null)
                            Text(
                              '나이: ${player.peakAge}',
                              style: _adminListMetaStyle,
                            ),
                          if (player.nationality != null &&
                              player.nationality!.isNotEmpty)
                            FutureBuilder<void>(
                              future: NationFlagService.instance
                                  .ensureLoaded(),
                              builder: (context, snapshot) {
                                final nation = NationFlagService.instance
                                    .resolve(player.nationality);
                                if (nation.flagUrl != null &&
                                    nation.flagUrl!.isNotEmpty) {
                                  return Image.network(
                                    nation.flagUrl!,
                                    width: 22,
                                    height: 16,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox.shrink(),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          Text(
                            _portraitExists[player.id] == null
                                ? '이미지: 확인중'
                                : _portraitExists[player.id]!
                                ? '이미지: 있음'
                                : '이미지: 없음',
                            style: _adminListMetaStyle,
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  '${player.detailPosition ?? player.position.label} · 랭크 ${player.rank ?? '-'}',
                                ),
                              ),
                              PlayerStyleChips(
                                styleLabels: resolveStyleLabels(
                                  styleIds: player.styleIds,
                                  stylesById: _stylesById,
                                ),
                                dense: true,
                              ),
                            ],
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
                            onPressed: () async {
                              final shouldRefresh = await context.push(
                                '/admin/${player.id}/edit',
                              );
                              if (!mounted) {
                                return;
                              }
                              if (shouldRefresh == true) {
                                await _load(showLoading: false);
                              }
                            },
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
  const AdminCoachesTab({
    super.key,
    required this.services,
    this.refreshToken,
  });

  final AppServices services;
  final String? refreshToken;

  @override
  State<AdminCoachesTab> createState() => _AdminCoachesTabState();
}

class _AdminCoachesTabState extends State<AdminCoachesTab> {
  final _csvService = CoachCsvService();
  final _listScrollController = ScrollController();
  List<Coach> _coaches = [];
  Map<String, Formation> _formations = {};
  Map<String, bool?> _coachPortraitExists = {};
  final Set<String> _portraitUploading = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AdminCoachesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken &&
        widget.refreshToken != null &&
        widget.refreshToken!.isNotEmpty) {
      _reloadKeepingScroll();
    }
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    super.dispose();
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
        _coachPortraitExists = {};
        _loading = false;
      });
      _refreshCoachPortraitStatus(_coaches);
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

  Future<void> _reloadKeepingScroll() async {
    final keepOffset = _listScrollController.hasClients
        ? _listScrollController.offset
        : 0.0;

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
        _coachPortraitExists = {};
        _error = null;
      });
      _refreshCoachPortraitStatus(_coaches);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_listScrollController.hasClients) {
          return;
        }
        final max = _listScrollController.position.maxScrollExtent;
        _listScrollController.jumpTo(keepOffset.clamp(0.0, max));
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
      });
    }
  }

  Future<void> _refreshCoachPortraitStatus(List<Coach> coaches) async {
    for (final coach in coaches) {
      _checkCoachPortrait(coach);
    }
  }

  Future<void> _checkCoachPortrait(Coach coach) async {
    final url = coach.portraitUrl?.trim();
    if (url == null || url.isEmpty) {
      setState(() => _coachPortraitExists[coach.id] = false);
      return;
    }

    setState(() => _coachPortraitExists[coach.id] = null);
    final exists = await portraitImageExists(url);
    if (!mounted) {
      return;
    }
    setState(() => _coachPortraitExists[coach.id] = exists);
  }

  Future<void> _uploadCoachPortrait(
    Coach coach,
    List<int> bytes,
    String fileName,
  ) async {
    if (_portraitUploading.contains(coach.id)) {
      return;
    }
    setState(() => _portraitUploading.add(coach.id));
    try {
      final dataUrl = portraitDataUrlFromBytes(bytes, fileName);
      final updated = await widget.services.coachService.patch(
        coach.id,
        {'portrait_url': dataUrl},
      );
      if (!mounted) {
        return;
      }
      setState(() {
        final index = _coaches.indexWhere((item) => item.id == coach.id);
        if (index >= 0) {
          _coaches[index] = updated;
        }
      });
      _checkCoachPortrait(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${coach.name} 이미지가 저장되었습니다.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 저장 실패: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _portraitUploading.remove(coach.id));
      }
    }
  }

  Future<void> _showDetail(Coach coach) async {
    final fresh =
        await widget.services.coachService.fetchById(coach.id) ?? coach;
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
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
          onAdd: () async {
            final shouldRefresh = await context.push('/admin/coaches/new');
            if (!mounted) {
              return;
            }
            if (shouldRefresh == true) {
              await _reloadKeepingScroll();
            }
          },
          addLabel: '감독 추가',
          onGenerator: () => context.go('/admin/coach-generator'),
          generatorLabel: '감독 생성기',
          onSecondaryGenerator: () =>
              context.go('/admin/coach-portrait-generator'),
          secondaryGeneratorLabel: '감독 이미지 생성',
        ),
        _RankCountSummary(
          entityLabel: '감독',
          rankCounts: _summarizeRanks(
            _coaches.map((coach) => coach.effectiveRank),
          ),
        ),
        Expanded(
          child: _coaches.isEmpty
              ? const Center(child: Text('등록된 감독이 없습니다. CSV를 가져오세요.'))
              : ListView.separated(
                  controller: _listScrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _coaches.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final coach = _coaches[index];
                    final compact = AdminLayout.isCompact(context);
                    return ListTile(
                      isThreeLine: compact,
                      contentPadding: compact
                          ? const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            )
                          : null,
                      leading: PortraitDropAvatar(
                        name: coach.name,
                        portraitUrl: coach.portraitUrl,
                        uploading: _portraitUploading.contains(coach.id),
                        onImageDropped: (bytes, fileName) =>
                            _uploadCoachPortrait(coach, bytes, fileName),
                      ),
                      title: _AdminListTitle(
                        name: coach.name,
                        meta: [
                          if (coach.fakeName != null &&
                              coach.fakeName!.isNotEmpty)
                            Text(
                              '가명: ${coach.fakeName}',
                              style: _adminListMetaStyle,
                            ),
                          if (coach.nationality != null &&
                              coach.nationality!.isNotEmpty)
                            FutureBuilder<void>(
                              future: NationFlagService.instance
                                  .ensureLoaded(),
                              builder: (context, snapshot) {
                                final nation = NationFlagService.instance
                                    .resolve(coach.nationality);
                                if (nation.flagUrl != null &&
                                    nation.flagUrl!.isNotEmpty) {
                                  return Image.network(
                                    nation.flagUrl!,
                                    width: 22,
                                    height: 16,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox.shrink(),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          Text(
                            _coachPortraitExists[coach.id] == null
                                ? '이미지: 확인중'
                                : _coachPortraitExists[coach.id]!
                                ? '이미지: 있음'
                                : '이미지: 없음',
                            style: _adminListMetaStyle,
                          ),
                        ],
                      ),
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
                            onPressed: () async {
                              final shouldRefresh = await context.push(
                                '/admin/coaches/${coach.id}/edit',
                              );
                              if (!mounted) {
                                return;
                              }
                              if (shouldRefresh == true) {
                                await _reloadKeepingScroll();
                              }
                            },
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
    final fresh =
        await widget.services.formationService.fetchById(item.id) ?? item;
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
        _AdminToolbar(onExport: _exportCsv),
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
                          item.formationType?.toUpperCase() ??
                              display.name.split('-').first,
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
        _AdminToolbar(onExport: _exportCsv),
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
                      leading: CircleAvatar(
                        child: Text(item.simplePosition.code.toUpperCase()),
                      ),
                      title: Text(item.name),
                      subtitle: Text(
                        '${item.mainStat}/${item.subStat} · ${item.id}',
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

class AdminNationFlagsTab extends StatefulWidget {
  const AdminNationFlagsTab({super.key, required this.services});

  final AppServices services;

  @override
  State<AdminNationFlagsTab> createState() => _AdminNationFlagsTabState();
}

class _AdminNationFlagsTabState extends State<AdminNationFlagsTab> {
  List<String> _nations = [];
  Map<String, String> _uploadedMap = {};
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
      final playersFuture = widget.services.playerService.fetchAll();
      final coachesFuture = widget.services.coachService.fetchAll();
      final uploadsFuture = widget.services.nationFlagImageService
          .fetchImageMap();
      await NationFlagService.instance.ensureLoaded();

      final results = await Future.wait([
        playersFuture,
        coachesFuture,
        uploadsFuture,
      ]);

      final players = results[0] as List<Player>;
      final coaches = results[1] as List<Coach>;
      final uploadedMap = Map<String, String>.from(
        results[2] as Map<String, String>,
      );

      final nations = <String>{};
      for (final player in players) {
        final nation = player.nationality?.trim();
        if (nation != null && nation.isNotEmpty) {
          nations.add(nation);
        }
      }
      for (final coach in coaches) {
        final nation = coach.nationality?.trim();
        if (nation != null && nation.isNotEmpty) {
          nations.add(nation);
        }
      }

      final sorted = nations.toList()..sort();

      if (!mounted) {
        return;
      }
      NationFlagService.instance.setOverrideUrls(uploadedMap);
      setState(() {
        _nations = sorted;
        _uploadedMap = uploadedMap;
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

  Future<void> _uploadForNation(String nation) async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) {
      return;
    }
    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미지 파일을 읽을 수 없습니다.')));
      return;
    }

    final dataUrl = _toDataUrl(bytes, file.extension ?? file.name);
    try {
      await widget.services.nationFlagImageService.upsert(
        nationality: nation,
        imageData: dataUrl,
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _uploadedMap[nation] = dataUrl;
      });
      NationFlagService.instance.setOverrideUrls(_uploadedMap);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$nation 국기 이미지를 저장했습니다.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('업로드 실패: $error')));
    }
  }

  Future<void> _showAddNationDialog() async {
    final nationController = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('국가 추가'),
        content: TextField(
          controller: nationController,
          decoration: const InputDecoration(
            labelText: '국가명',
            hintText: '예: 남아프리카공화국',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('다음'),
          ),
        ],
      ),
    );

    if (saved != true) {
      nationController.dispose();
      return;
    }

    final nation = nationController.text.trim();
    nationController.dispose();
    if (nation.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('국가명을 입력해 주세요.')));
      return;
    }

    await _uploadForNation(nation);
    if (!mounted) {
      return;
    }
    setState(() {
      if (!_nations.contains(nation)) {
        _nations.add(nation);
        _nations.sort();
      }
    });
  }

  bool _hasFlag(String nation) {
    if (_uploadedMap[nation]?.isNotEmpty == true) {
      return true;
    }
    final resolved = NationFlagService.instance.resolve(nation);
    return resolved.flagUrl?.isNotEmpty == true;
  }

  String? _flagUrl(String nation) {
    return _uploadedMap[nation] ??
        NationFlagService.instance.resolve(nation).flagUrl;
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
        Material(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '선수/감독 국가 목록 (${_nations.length}개) · 국기 있음/없음 확인 · 국가별 업로드',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                IconButton(
                  tooltip: '국가 추가',
                  onPressed: _showAddNationDialog,
                  icon: const Icon(Icons.add_circle_outline),
                ),
                IconButton(
                  tooltip: '새로고침',
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _nations.isEmpty
              ? const Center(child: Text('선수/감독에 설정된 국가가 없습니다.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _nations.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final nation = _nations[index];
                    final flagUrl = _flagUrl(nation);
                    final hasFlag = _hasFlag(nation);
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          width: 36,
                          height: 24,
                          child: flagUrl == null || flagUrl.isEmpty
                              ? Container(
                                  color: Colors.black12,
                                  child: const Icon(
                                    Icons.flag_outlined,
                                    size: 16,
                                  ),
                                )
                              : Image.network(
                                  flagUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.black12,
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 16,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      title: Text(nation),
                      subtitle: Text(hasFlag ? '국기 있음' : '국기 없음'),
                      trailing: FilledButton.icon(
                        onPressed: () => _uploadForNation(nation),
                        icon: const Icon(Icons.upload_file),
                        label: const Text('업로드'),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class AdminClubEmblemsTab extends StatefulWidget {
  const AdminClubEmblemsTab({super.key, required this.services});

  final AppServices services;

  @override
  State<AdminClubEmblemsTab> createState() => _AdminClubEmblemsTabState();
}

enum _ClubEmblemSortType {
  id('ID순'),
  grade('랭크순'),
  seed('시드순');

  const _ClubEmblemSortType(this.label);
  final String label;
}

class _AdminClubEmblemsTabState extends State<AdminClubEmblemsTab> {
  List<ClubEmblem> _items = [];
  _ClubEmblemSortType _sortType = _ClubEmblemSortType.id;
  bool _loading = true;
  String? _error;

  List<ClubEmblem> get _sortedItems {
    final list = List<ClubEmblem>.from(_items);
    int idNumber(ClubEmblem item) => int.tryParse(item.id) ?? 9999;

    switch (_sortType) {
      case _ClubEmblemSortType.id:
        list.sort((a, b) => idNumber(a).compareTo(idNumber(b)));
      case _ClubEmblemSortType.grade:
        list.sort((a, b) {
          final gradeCompare = a.grade.compareTo(b.grade);
          if (gradeCompare != 0) {
            return gradeCompare;
          }
          return idNumber(a).compareTo(idNumber(b));
        });
      case _ClubEmblemSortType.seed:
        list.sort((a, b) {
          final seedCompare = a.seedType.compareTo(b.seedType);
          if (seedCompare != 0) {
            return seedCompare;
          }
          return idNumber(a).compareTo(idNumber(b));
        });
    }
    return list;
  }

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
      final items = await widget.services.clubEmblemService.fetchAll();
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

  Future<void> _uploadImage(ClubEmblem item) async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) {
      return;
    }
    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미지 파일을 읽을 수 없습니다.')));
      return;
    }

    final dataUrl = _toDataUrl(bytes, file.extension ?? file.name);
    try {
      await widget.services.clubEmblemService.updateImage(
        id: item.id,
        imageData: dataUrl,
      );
      await _load();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('앰블럼 ${item.id} 이미지 저장 완료')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('이미지 저장 실패: $error')));
    }
  }

  Future<void> _deleteItem(ClubEmblem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('앰블럼 삭제'),
        content: Text('ID ${item.id} 앰블럼을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await widget.services.clubEmblemService.delete(item.id);
      await _load();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('앰블럼 ${item.id}을(를) 삭제했습니다.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('삭제 실패: $error')));
    }
  }

  Future<void> _editMeta(ClubEmblem item) async {
    var grade = item.grade;
    final seedController = TextEditingController(text: item.seedType);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('앰블럼 ${item.id} 수정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: grade,
                decoration: const InputDecoration(labelText: '등급'),
                items: const [1, 2, 3]
                    .map(
                      (value) => DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value등급'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setDialogState(() => grade = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: seedController,
                decoration: const InputDecoration(labelText: '시드종류'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) {
      seedController.dispose();
      return;
    }

    final seedType = seedController.text.trim().isEmpty
        ? '일반시드'
        : seedController.text.trim();
    seedController.dispose();

    try {
      await widget.services.clubEmblemService.updateMeta(
        id: item.id,
        grade: grade,
        seedType: seedType,
      );
      await _load();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('앰블럼 ${item.id} 정보를 저장했습니다.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('수정 실패: $error')));
    }
  }

  Future<void> _showAddDialog() async {
    final seedController = TextEditingController(text: '일반시드');
    var grade = 1;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('클럽앰블럼 데이터 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ID는 자동으로 생성됩니다.\n(예: 061, 062, 063...)',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: grade,
                decoration: const InputDecoration(labelText: '랭크(등급)'),
                items: const [1, 2, 3]
                    .map(
                      (value) => DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value등급'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setDialogState(() => grade = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: seedController,
                decoration: const InputDecoration(labelText: '시드종류'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) {
      seedController.dispose();
      return;
    }

    final seedType = seedController.text.trim().isEmpty
        ? '일반시드'
        : seedController.text.trim();

    seedController.dispose();

    try {
      final createdId = await widget.services.clubEmblemService.createNext(
        grade: grade,
        seedType: seedType,
      );
      await _load();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('앰블럼 $createdId 데이터를 추가했습니다.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('추가 실패: $error')));
    }
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
        Material(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '클럽앰블럼 001~060 · 등급(1~3) · 이미지파일 · 시드종류 관리',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<_ClubEmblemSortType>(
                      value: _sortType,
                      isExpanded: true,
                      items: _ClubEmblemSortType.values
                          .map(
                            (type) => DropdownMenuItem<_ClubEmblemSortType>(
                              value: type,
                              child: Text(type.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() => _sortType = value);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: '데이터 추가',
                  onPressed: _showAddDialog,
                  icon: const Icon(Icons.add_circle_outline),
                ),
                IconButton(
                  tooltip: '새로고침',
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _sortedItems.isEmpty
              ? const Center(child: Text('클럽앰블럼 데이터가 없습니다.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sortedItems.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _sortedItems[index];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: (item.imageData?.isNotEmpty ?? false)
                              ? Image.network(
                                  item.imageData!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.black12,
                                    child: const Icon(
                                      Icons.shield_outlined,
                                      size: 16,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: Colors.black12,
                                  child: const Icon(
                                    Icons.shield_outlined,
                                    size: 16,
                                  ),
                                ),
                        ),
                      ),
                      title: Text('ID ${item.id} · ${item.grade}등급'),
                      subtitle: Text('시드종류: ${item.seedType}'),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _uploadImage(item),
                            icon: const Icon(Icons.upload_file),
                            label: const Text('업로드'),
                          ),
                          FilledButton.icon(
                            onPressed: () => _editMeta(item),
                            icon: const Icon(Icons.edit),
                            label: const Text('수정'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _deleteItem(item),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('삭제'),
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

class AdminPlayerStylesTab extends StatefulWidget {
  const AdminPlayerStylesTab({super.key, required this.services});

  final AppServices services;

  @override
  State<AdminPlayerStylesTab> createState() => _AdminPlayerStylesTabState();
}

class _AdminPlayerStylesTabState extends State<AdminPlayerStylesTab> {
  List<PlayerStyle> _items = [];
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
      final items = await widget.services.playerStyleService.fetchAll();
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

  List<PlayerStyle> _itemsForCategory(PlayerStyleCategory category) {
    return _items.where((item) => item.category == category).toList();
  }

  Future<void> _editLabel(PlayerStyle item) async {
    final controller = TextEditingController(text: item.labelKo);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('스타일 수정 · ${item.id}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '표시 이름',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    if (saved != true || !mounted) {
      controller.dispose();
      return;
    }
    final labelKo = controller.text.trim();
    controller.dispose();
    if (labelKo.isEmpty) {
      return;
    }
    try {
      await widget.services.playerStyleService.updateLabel(
        id: item.id,
        labelKo: labelKo,
      );
      await _load();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LoadingView(message: '선수 스타일 불러오는 중...');
    }
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: const Card(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: PlayerStyleRankGuide(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: '새로고침',
              onPressed: _load,
              icon: const Icon(Icons.refresh),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final category in PlayerStyleCategory.ordered) ...[
                Card(
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    title: Text(
                      category.labelKo,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('${_itemsForCategory(category).length}개'),
                    children: [
                      for (final item in _itemsForCategory(category))
                        ListTile(
                          dense: true,
                          title: Text(item.labelKo),
                          subtitle: Text(item.id),
                          trailing: IconButton(
                            tooltip: '이름 수정',
                            onPressed: () => _editLabel(item),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

String _toDataUrl(List<int> bytes, String extensionOrName) {
  return portraitDataUrlFromBytes(bytes, extensionOrName);
}

const _adminListMetaStyle = TextStyle(fontSize: 12, color: Colors.grey);

class _AdminListTitle extends StatelessWidget {
  const _AdminListTitle({required this.name, required this.meta});

  final String name;
  final List<Widget> meta;

  @override
  Widget build(BuildContext context) {
    final compact = AdminLayout.isCompact(context);
    final nameWidget = Text(
      name,
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
    if (meta.isEmpty) {
      return nameWidget;
    }

    final metaWidget = Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: meta,
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          nameWidget,
          const SizedBox(height: 4),
          metaWidget,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: nameWidget),
        const SizedBox(width: 8),
        Flexible(child: metaWidget),
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
    final total =
        rankCounts.byRank.values.fold<int>(0, (sum, count) => sum + count) +
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
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            for (var rank = 1; rank <= 5; rank++)
              _RankCountChip(rank: rank, count: rankCounts.byRank[rank] ?? 0),
            if (rankCounts.unranked > 0)
              Text(
                '미지정 ${rankCounts.unranked}명',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
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
