import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/player.dart';
import '../../models/player_position.dart';
import '../../services/player_service.dart';
import '../../widgets/common_widgets.dart';

class PlayerListPage extends StatefulWidget {
  const PlayerListPage({super.key, required this.playerService});

  final PlayerService playerService;

  @override
  State<PlayerListPage> createState() => _PlayerListPageState();
}

class _PlayerListPageState extends State<PlayerListPage> {
  final _searchController = TextEditingController();
  List<Player> _players = [];
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

      final players = await widget.playerService.fetchAll(
        search: _searchController.text,
        position: filter,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _players = players;
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
                                title: Text(player.name),
                                subtitle: Text(
                                  [
                                    player.position.label,
                                    if (player.fakeName != null) '가명: ${player.fakeName}',
                                    if (player.rank != null) '랭크 ${player.rank}',
                                  ].join(' · '),
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
