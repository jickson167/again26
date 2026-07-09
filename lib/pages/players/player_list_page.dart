import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/player.dart';
import '../../models/player_position.dart';
import '../../models/player_style.dart';
import '../../services/player_service.dart';
import '../../services/player_style_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/player_style_chips.dart';
import '../../widgets/seed_name_chips.dart';
import '../../utils/country_flag.dart';
import '../../utils/player_portrait.dart';
import '../../utils/portrait_image_check.dart';

class PlayerListPage extends StatefulWidget {
  const PlayerListPage({
    super.key,
    required this.playerService,
    required this.playerStyleService,
  });

  final PlayerService playerService;
  final PlayerStyleService playerStyleService;

  @override
  State<PlayerListPage> createState() => _PlayerListPageState();
}

class _PlayerListPageState extends State<PlayerListPage> {
  final _searchController = TextEditingController();
  List<Player> _players = [];
  Map<String, PlayerStyle> _stylesById = {};
  final Map<String, bool?> _portraitExists = {};
  bool _loading = true;
  String? _error;
  PlayerPosition? _positionFilter;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _loadPlayers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final filter = _positionFilter == null
          ? null
          : PlayerPositionFilter.values.firstWhere(
              (item) => item.code == _positionFilter!.code,
            );

      final results = await Future.wait([
        widget.playerService.fetchAll(
          search: _searchController.text,
          position: filter,
        ),
        widget.playerStyleService.fetchByIdMap(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _players = results[0] as List<Player>;
        _stylesById = results[1] as Map<String, PlayerStyle>;
        _portraitExists.clear();
        _loading = false;
      });
      _refreshPortraitStatus(_players);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('선수 목록'),
        actions: [
          IconButton(
            tooltip: '관리자',
            onPressed: () => context.go('/admin'),
            icon: const Icon(Icons.admin_panel_settings),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '이름 또는 가명 검색',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadPlayers();
                        },
                      ),
                    ),
                    onSubmitted: (_) => _loadPlayers(),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<PlayerPosition?>(
                  value: _positionFilter,
                  hint: const Text('포지션'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('전체')),
                    ...PlayerPosition.values.map(
                      (position) => DropdownMenuItem(
                        value: position,
                        child: Text(position.label),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _positionFilter = value);
                    _loadPlayers();
                  },
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _loadPlayers, child: const Text('검색')),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _error != null
                    ? ErrorView(message: _error!, onRetry: _loadPlayers)
                    : _players.isEmpty
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
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        player.name,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Wrap(
                                      spacing: 6,
                                      children: [
                                        if (player.nationality != null)
                                          Text(
                                            flagEmoji(player.nationality) ?? '',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        if (player.fakeName != null)
                                          Text('가명: ${player.fakeName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        if (player.peakAge != null)
                                          Text('나이: ${player.peakAge}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        Text(
                                          _portraitExists[player.id] == null
                                              ? '이미지: 확인중'
                                              : _portraitExists[player.id]!
                                                  ? '이미지: 있음'
                                                  : '이미지: 없음',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
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
                                            [
                                              player.position.label,
                                              if (player.fakeName != null)
                                                '가명: ${player.fakeName}',
                                              if (player.rank != null)
                                                '랭크 ${player.rank}',
                                            ].join(' · '),
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
                                trailing: IconButton(
                                  tooltip: '자세히 보기',
                                  icon: const Icon(Icons.search),
                                  onPressed: () => context.go('/players/${player.id}'),
                                ),
                                onTap: () => context.go('/players/${player.id}'),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
