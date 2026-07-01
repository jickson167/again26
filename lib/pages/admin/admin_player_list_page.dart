import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/player.dart';
import '../../services/csv_service.dart';
import '../../services/player_service.dart';
import '../../widgets/common_widgets.dart';

class AdminPlayerListPage extends StatefulWidget {
  const AdminPlayerListPage({super.key, required this.playerService});

  final PlayerService playerService;

  @override
  State<AdminPlayerListPage> createState() => _AdminPlayerListPageState();
}

class _AdminPlayerListPageState extends State<AdminPlayerListPage> {
  final _csvService = CsvService();
  List<Player> _players = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final players = await widget.playerService.fetchAll();
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

    try {
      await widget.playerService.delete(player.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${player.name} 선수가 삭제되었습니다.')),
      );
      await _loadPlayers();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: $error')),
      );
    }
  }

  Future<void> _exportCsv() async {
    try {
      final csv = _csvService.exportPlayers(_players);
      _csvService.downloadCsv(csv);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV 내보내기가 시작되었습니다.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('내보내기 실패: $error')),
      );
    }
  }

  Future<void> _importCsv() async {
    try {
      final players = await _csvService.importFromPicker();
      if (players.isEmpty) {
        return;
      }

      await widget.playerService.upsertMany(players);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${players.length}명의 선수를 가져왔습니다.')),
      );
      await _loadPlayers();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('가져오기 실패: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('관리자 - 선수 관리'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            tooltip: 'CSV 가져오기',
            onPressed: _importCsv,
            icon: const Icon(Icons.upload_file),
          ),
          IconButton(
            tooltip: 'CSV 내보내기',
            onPressed: _exportCsv,
            icon: const Icon(Icons.download),
          ),
          IconButton(
            tooltip: '선수 추가',
            onPressed: () => context.go('/admin/new'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/admin/new'),
        icon: const Icon(Icons.add),
        label: const Text('선수 추가'),
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _loadPlayers)
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        child: ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: const Text('CSV Import / Export'),
                          subtitle: Text(
                            '컬럼: ${CsvService.headers.take(8).join(', ')} ... '
                            '(총 ${CsvService.headers.length}개)',
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _players.isEmpty
                          ? const Center(child: Text('등록된 선수가 없습니다.'))
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                    '${player.position.label} · 랭크 ${player.rank ?? '-'}',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: '수정',
                                        onPressed: () =>
                                            context.go('/admin/${player.id}/edit'),
                                        icon: const Icon(Icons.edit),
                                      ),
                                      IconButton(
                                        tooltip: '삭제',
                                        onPressed: () => _deletePlayer(player),
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                    ],
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
