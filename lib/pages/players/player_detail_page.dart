import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/player.dart';
import '../../services/player_service.dart';
import '../../widgets/common_widgets.dart';

class PlayerDetailPage extends StatefulWidget {
  const PlayerDetailPage({
    super.key,
    required this.playerService,
    required this.playerId,
  });

  final PlayerService playerService;
  final String playerId;

  @override
  State<PlayerDetailPage> createState() => _PlayerDetailPageState();
}

class _PlayerDetailPageState extends State<PlayerDetailPage> {
  Player? _player;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlayer();
  }

  Future<void> _loadPlayer() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final player = await widget.playerService.fetchById(widget.playerId);
      if (!mounted) {
        return;
      }

      setState(() {
        _player = player;
        _loading = false;
        if (player == null) {
          _error = '선수를 찾을 수 없습니다.';
        }
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
        title: const Text('선수 상세'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/players'),
        ),
        actions: [
          if (_player != null)
            IconButton(
              tooltip: '수정',
              onPressed: () => context.go('/admin/${_player!.id}/edit'),
              icon: const Icon(Icons.edit),
            ),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _loadPlayer)
              : _player == null
                  ? const SizedBox.shrink()
                  : _PlayerDetailBody(player: _player!),
    );
  }
}

class _PlayerDetailBody extends StatelessWidget {
  const _PlayerDetailBody({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PlayerAvatar(
                    name: player.name,
                    portraitUrl: player.portraitUrl,
                    radius: 48,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(player.name, style: Theme.of(context).textTheme.headlineSmall),
                        if (player.fakeName != null)
                          Text('가명: ${player.fakeName}'),
                        Text(
                          [
                            player.position.label,
                            if (player.rank != null) '랭크 ${player.rank}',
                            if (player.ageStage != null) '${player.ageStage}세',
                            if (player.nationality != null) player.nationality,
                          ].whereType<String>().join(' · '),
                        ),
                        if (player.peakAge != null)
                          Text(
                            '전성기 나이 참고: ${player.peakAge}세',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: '기본 정보',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (player.height != null) Text('키: ${player.height} cm'),
                    if (player.weight != null) Text('몸무게: ${player.weight} kg'),
                    if (player.ageStage != null) Text('현재나이: ${player.ageStage}세'),
                    if (player.peakAge != null)
                      Text('전성기 나이 (참고): ${player.peakAge}세'),
                    if (player.createdAt != null)
                      Text('등록: ${dateFormat.format(player.createdAt!.toLocal())}'),
                    if (player.updatedAt != null)
                      Text('수정: ${dateFormat.format(player.updatedAt!.toLocal())}'),
                  ],
                ),
              ),
              SectionCard(
                title: '능력치',
                child: Column(
                  children: [
                    StatBar(label: '스피드', value: player.speed),
                    StatBar(label: '파워', value: player.power),
                    StatBar(label: '기술', value: player.technique),
                    StatBar(label: 'PK', value: player.pkAbility),
                    StatBar(label: 'FK', value: player.fkAbility),
                    StatBar(label: 'CK', value: player.ckAbility),
                    StatBar(label: '리더십', value: player.leadership),
                    const SizedBox(height: 8),
                    DualStatBar(
                      labelLeft: '지력',
                      labelRight: '감각',
                      leftValue: player.intelligenceValue,
                      rightValue: player.senseValue,
                    ),
                    const SizedBox(height: 8),
                    DualStatBar(
                      labelLeft: '개인',
                      labelRight: '조직',
                      leftValue: player.individualValue,
                      rightValue: player.organizationValue,
                    ),
                  ],
                ),
              ),
              SectionCard(
                title: '적정 포지션 (1~13)',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 1; i <= Player.positionFitCount; i++)
                      Chip(
                        label: Text('P$i: ${player.positionFit[i] ?? 0}'),
                      ),
                  ],
                ),
              ),
              SectionCard(
                title: '성장 타입 (1기~10기)',
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('기')),
                      DataColumn(label: Text('스피드')),
                      DataColumn(label: Text('파워')),
                      DataColumn(label: Text('기술')),
                      DataColumn(label: Text('평균')),
                    ],
                    rows: [
                      for (var i = 0; i < Player.growthPeriodCount; i++)
                        DataRow(
                          color: WidgetStateProperty.resolveWith((states) {
                            final growth = player.growthType[i];
                            final avg = (growth.speed + growth.power + growth.technique) / 3;
                            final peakAvg = player.growthType
                                .map((g) => (g.speed + g.power + g.technique) / 3)
                                .reduce((a, b) => a > b ? a : b);
                            if (avg >= peakAvg - 0.001) {
                              return Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35);
                            }
                            return null;
                          }),
                          cells: [
                            DataCell(Text('${i + 1}기')),
                            DataCell(Text('${player.growthType[i].speed}')),
                            DataCell(Text('${player.growthType[i].power}')),
                            DataCell(Text('${player.growthType[i].technique}')),
                            DataCell(Text(
                              ((player.growthType[i].speed +
                                      player.growthType[i].power +
                                      player.growthType[i].technique) /
                                  3)
                                  .toStringAsFixed(1),
                            )),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
