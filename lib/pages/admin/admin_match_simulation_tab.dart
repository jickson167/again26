import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/game_club.dart';
import '../../models/match_simulation_dto.dart';
import '../../models/player.dart';
import '../../services/app_services.dart';
import '../../utils/game_club_to_sim_snapshot.dart';
import '../../widgets/admin/match_sim_result_panel.dart';
import '../../widgets/common_widgets.dart';

/// 매니저 데이터 관리 · 경기 시뮬레이션 탭 (지정 / 랜덤).
class AdminMatchSimulationTab extends StatefulWidget {
  const AdminMatchSimulationTab({super.key, required this.services});

  final AppServices services;

  @override
  State<AdminMatchSimulationTab> createState() =>
      _AdminMatchSimulationTabState();
}

class _AdminMatchSimulationTabState extends State<AdminMatchSimulationTab>
    with SingleTickerProviderStateMixin {
  late final TabController _subTabController;
  List<GameClub> _clubs = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
    _loadClubs();
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  Future<void> _loadClubs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final clubs = await widget.services.gameClubService.fetchClubs(
        limit: 100,
        playerService: widget.services.playerService,
        coachService: widget.services.coachService,
        formationService: widget.services.formationService,
      );
      if (!mounted) return;
      setState(() {
        _clubs = clubs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LoadingView(message: '구단 목록 불러오는 중...');
    }
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _loadClubs);
    }

    return Column(
      children: [
        TabBar(
          controller: _subTabController,
          tabs: const [
            Tab(text: '지정 경기 시뮬레이션'),
            Tab(text: '랜덤 시뮬레이션'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _FixedMatchSimPane(
                clubs: _clubs,
                services: widget.services,
                onRefresh: _loadClubs,
              ),
              _RandomMatchSimPane(clubs: _clubs, onRefresh: _loadClubs),
            ],
          ),
        ),
      ],
    );
  }
}

String _clubListLine(GameClub club) {
  return '${club.clubName} / ${club.leagueTier.label} / ${club.leagueStanding}위';
}

int _newSeed() => Random().nextInt(1 << 31);

// ---------------------------------------------------------------------------
// 지정 경기
// ---------------------------------------------------------------------------

class _FixedMatchSimPane extends StatefulWidget {
  const _FixedMatchSimPane({
    required this.clubs,
    required this.services,
    required this.onRefresh,
  });

  final List<GameClub> clubs;
  final AppServices services;
  final VoidCallback onRefresh;

  @override
  State<_FixedMatchSimPane> createState() => _FixedMatchSimPaneState();
}

class _FixedMatchSimPaneState extends State<_FixedMatchSimPane> {
  GameClub? _teamA;
  GameClub? _teamB;
  bool _aIsHome = true;
  bool _homeAdvantage = true;
  bool _running = false;
  late final TextEditingController _seedController;
  MatchSimApiResponse? _response;
  String? _runError;

  @override
  void initState() {
    super.initState();
    _seedController = TextEditingController(text: '${_newSeed()}');
  }

  @override
  void dispose() {
    _seedController.dispose();
    super.dispose();
  }

  void _toggleSelect(GameClub club) {
    setState(() {
      if (_teamA?.id == club.id) {
        _teamA = _teamB;
        _teamB = null;
        return;
      }
      if (_teamB?.id == club.id) {
        _teamB = null;
        return;
      }
      if (_teamA == null) {
        _teamA = club;
        return;
      }
      if (_teamB == null) {
        _teamB = club;
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최대 2팀까지 선택할 수 있습니다.')),
      );
    });
  }

  bool _isSelected(GameClub club) =>
      _teamA?.id == club.id || _teamB?.id == club.id;

  void _swapHomeAway() {
    setState(() => _aIsHome = !_aIsHome);
  }

  int? _parsedSeed() {
    final n = int.tryParse(_seedController.text.trim());
    if (n == null || n < 0) return null;
    return n;
  }

  Future<void> _run({required bool freshSeed}) async {
    final a = _teamA;
    final b = _teamB;
    if (a == null || b == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('두 팀을 모두 선택하세요.')),
      );
      return;
    }
    if (freshSeed) {
      _seedController.text = '${_newSeed()}';
    }
    final seed = _parsedSeed();
    if (seed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('유효한 seed(0 이상 정수)를 입력하세요.')),
      );
      return;
    }

    final home = _aIsHome ? a : b;
    final away = _aIsHome ? b : a;
    if (home.starters.isEmpty || away.starters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선발 스쿼드가 비어 있는 구단이 있습니다.')),
      );
      return;
    }

    setState(() {
      _running = true;
      _runError = null;
    });

    try {
      final input = GameClubToSimSnapshot.buildInput(
        home: home,
        away: away,
        seed: seed,
        homeAdvantage: _homeAdvantage,
      );
      final response =
          await widget.services.matchSimulationApi.runDryRun(input: input);
      if (!mounted) return;
      setState(() {
        _response = response;
        _running = false;
        if (!response.ok || response.result == null) {
          _runError = response.error ?? '시뮬레이션 실패';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _running = false;
        _runError = '$e';
        _response = null;
      });
    }
  }

  Future<void> _copyJson() async {
    final raw = _response?.raw;
    if (raw == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('복사할 결과가 없습니다.')),
      );
      return;
    }
    final text = const JsonEncoder.withIndent('  ').convert(raw);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('결과 JSON 복사됨')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 320,
            child: _ClubPickList(
              clubs: widget.clubs,
              isSelected: _isSelected,
              onSelect: _toggleSelect,
              onRefresh: widget.onRefresh,
              selectionHint: '최대 2팀 선택',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _teamA == null || _teamB == null
                ? const Center(
                    child: Text('왼쪽에서 두 팀을 선택하면 대진 정보가 표시됩니다.'),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MaterialBanner(
                        content: const Text(
                          '테스트 경기 · DB 저장 안 됨 · 선수 통산 기록 반영 안 됨',
                        ),
                        leading: const Icon(Icons.science_outlined),
                        backgroundColor:
                            Theme.of(context).colorScheme.secondaryContainer,
                        actions: const [SizedBox.shrink()],
                      ),
                      Expanded(
                        flex: 2,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _MatchupPanel(
                                teamA: _teamA!,
                                teamB: _teamB!,
                                aIsHome: _aIsHome,
                                onHomeChanged: (aHome) =>
                                    setState(() => _aIsHome = aHome),
                              ),
                              const SizedBox(height: 8),
                              _DryRunControls(
                                seedController: _seedController,
                                homeAdvantage: _homeAdvantage,
                                running: _running,
                                onHomeAdvantageChanged: (v) =>
                                    setState(() => _homeAdvantage = v),
                                onNewSeed: () => setState(
                                  () => _seedController.text = '${_newSeed()}',
                                ),
                                onSwap: _swapHomeAway,
                                onStart: () => _run(freshSeed: false),
                                onRerunSame: () => _run(freshSeed: false),
                                onRerunNew: () => _run(freshSeed: true),
                                onCopyJson: _copyJson,
                                hasResult: _response?.raw != null,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        flex: 3,
                        child: _running
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : _runError != null && _response?.result == null
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        _runError!,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  )
                                : _response?.result != null
                                    ? MatchSimResultPanel(
                                        response: _response!,
                                      )
                                    : const Center(
                                        child: Text(
                                          '테스트 시작 후 Edge dry-run 결과가 여기에 표시됩니다.',
                                        ),
                                      ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _DryRunControls extends StatelessWidget {
  const _DryRunControls({
    required this.seedController,
    required this.homeAdvantage,
    required this.running,
    required this.onHomeAdvantageChanged,
    required this.onNewSeed,
    required this.onSwap,
    required this.onStart,
    required this.onRerunSame,
    required this.onRerunNew,
    required this.onCopyJson,
    required this.hasResult,
  });

  final TextEditingController seedController;
  final bool homeAdvantage;
  final bool running;
  final ValueChanged<bool> onHomeAdvantageChanged;
  final VoidCallback onNewSeed;
  final VoidCallback onSwap;
  final VoidCallback onStart;
  final VoidCallback onRerunSame;
  final VoidCallback onRerunNew;
  final VoidCallback onCopyJson;
  final bool hasResult;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: seedController,
                    enabled: !running,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Seed',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: running ? null : onNewSeed,
                  child: const Text('새 seed'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: running ? null : onSwap,
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('홈/원정 맞바꾸기'),
                ),
              ],
            ),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('홈 어드밴티지'),
              value: homeAdvantage,
              onChanged: running ? null : onHomeAdvantageChanged,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: running ? null : onStart,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('테스트 시작'),
                ),
                OutlinedButton(
                  onPressed: running || !hasResult ? null : onRerunSame,
                  child: const Text('같은 seed 재실행'),
                ),
                OutlinedButton(
                  onPressed: running ? null : onRerunNew,
                  child: const Text('새 seed 재실행'),
                ),
                OutlinedButton.icon(
                  onPressed: running || !hasResult ? null : onCopyJson,
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('결과 JSON 복사'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 랜덤 시뮬레이션
// ---------------------------------------------------------------------------

class _RandomMatchSimPane extends StatefulWidget {
  const _RandomMatchSimPane({required this.clubs, required this.onRefresh});

  final List<GameClub> clubs;
  final VoidCallback onRefresh;

  @override
  State<_RandomMatchSimPane> createState() => _RandomMatchSimPaneState();
}

class _RandomMatchSimPaneState extends State<_RandomMatchSimPane> {
  GameClub? _selected;
  late final TextEditingController _countController;
  final List<String> _logLines = [];

  @override
  void initState() {
    super.initState();
    _countController = TextEditingController(text: '10');
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  void _toggleSelect(GameClub club) {
    setState(() {
      _selected = _selected?.id == club.id ? null : club;
    });
  }

  int _parsedCount() {
    final n = int.tryParse(_countController.text.trim()) ?? 10;
    return n.clamp(1, 1000);
  }

  void _startSimulation() {
    final club = _selected;
    if (club == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('구단을 하나 선택하세요.')),
      );
      return;
    }
    final n = _parsedCount();
    setState(() {
      _countController.text = '$n';
      _logLines.add(
        '[준비] ${club.clubName} vs 랜덤 $n팀 — 후속 구현 예정',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 340,
            child: _ClubPickList(
              clubs: widget.clubs,
              isSelected: (c) => _selected?.id == c.id,
              onSelect: _toggleSelect,
              onRefresh: widget.onRefresh,
              selectionHint: '1팀 선택',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _selected == null
                ? const Center(child: Text('왼쪽에서 구단을 하나 선택하세요.'))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 2,
                        child: SingleChildScrollView(
                          child: _RandomMatchupSummary(
                            club: _selected!,
                            countController: _countController,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _startSimulation,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('시뮬레이션 시작'),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        flex: 3,
                        child: _ResultLogPanel(
                          lines: _logLines,
                          emptyHint: '랜덤 시뮬은 후속 단계에서 Edge API로 연결됩니다.',
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 공유 위젯
// ---------------------------------------------------------------------------

class _ClubPickList extends StatelessWidget {
  const _ClubPickList({
    required this.clubs,
    required this.isSelected,
    required this.onSelect,
    required this.onRefresh,
    required this.selectionHint,
  });

  final List<GameClub> clubs;
  final bool Function(GameClub) isSelected;
  final void Function(GameClub) onSelect;
  final VoidCallback onRefresh;
  final String selectionHint;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '구단 목록 (${clubs.length}) · $selectionHint',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: '새로고침',
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, size: 20),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: clubs.isEmpty
                ? const Center(child: Text('생성된 구단이 없습니다.'))
                : ListView.separated(
                    itemCount: clubs.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final club = clubs[index];
                      final selected = isSelected(club);
                      return ListTile(
                        dense: true,
                        selected: selected,
                        title: Text(
                          _clubListLine(club),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                        trailing: TextButton(
                          onPressed: () => onSelect(club),
                          child: Text(selected ? '해제' : '선택'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MatchupPanel extends StatelessWidget {
  const _MatchupPanel({
    required this.teamA,
    required this.teamB,
    required this.aIsHome,
    required this.onHomeChanged,
  });

  final GameClub teamA;
  final GameClub teamB;
  final bool aIsHome;
  final ValueChanged<bool> onHomeChanged;

  @override
  Widget build(BuildContext context) {
    final home = aIsHome ? teamA : teamB;
    final away = aIsHome ? teamB : teamA;
    final homeTag = aIsHome ? 'A팀' : 'B팀';
    final awayTag = aIsHome ? 'B팀' : 'A팀';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _TeamInfoHeader(label: '$homeTag · 홈', club: home),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Text('vs', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: _TeamInfoHeader(label: '$awayTag · 원정', club: away),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('A팀 홈'),
                value: aIsHome,
                onChanged: (v) {
                  if (v == true) onHomeChanged(true);
                },
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('B팀 홈'),
                value: !aIsHome,
                onChanged: (v) {
                  if (v == true) onHomeChanged(false);
                },
              ),
            ),
          ],
        ),
        const Divider(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _ClubMark(club: home, badge: '홈')),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 24),
              child: Text('vs', style: TextStyle(fontSize: 18)),
            ),
            Expanded(child: _ClubMark(club: away, badge: '원정')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _SquadBlock(title: '홈 선발', players: home.starters),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SquadBlock(title: '원정 선발', players: away.starters),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _SquadBlock(title: '홈 후보', players: home.bench)),
            const SizedBox(width: 8),
            Expanded(child: _SquadBlock(title: '원정 후보', players: away.bench)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text('감독: ${home.coach.name}', style: _metaStyle),
            ),
            Expanded(
              child: Text('감독: ${away.coach.name}', style: _metaStyle),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                '포메이션: ${home.formation.name}',
                style: _metaStyle,
              ),
            ),
            Expanded(
              child: Text(
                '포메이션: ${away.formation.name}',
                style: _metaStyle,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static const _metaStyle = TextStyle(fontSize: 13);
}

class _TeamInfoHeader extends StatelessWidget {
  const _TeamInfoHeader({required this.label, required this.club});

  final String label;
  final GameClub club;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        Text(
          club.clubName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          '${club.leagueTier.label} · ${club.leagueStanding}위 · 전력 ${club.teamPower}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ClubMark extends StatelessWidget {
  const _ClubMark({required this.club, this.badge});

  final GameClub club;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final url = club.clubLogoUrl;
    return Column(
      children: [
        if (badge != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              badge!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        CircleAvatar(
          radius: 36,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          backgroundImage: url != null && url.isNotEmpty
              ? NetworkImage(url)
              : null,
          child: url == null || url.isEmpty
              ? const Icon(Icons.shield, size: 36)
              : null,
        ),
        const SizedBox(height: 4),
        Text(club.clubName, textAlign: TextAlign.center, maxLines: 2),
      ],
    );
  }
}

class _SquadBlock extends StatelessWidget {
  const _SquadBlock({required this.title, required this.players});

  final String title;
  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        for (var i = 0; i < players.length; i++)
          Text(
            '${i + 1}. ${players[i].name} (${players[i].position.label})',
            style: const TextStyle(fontSize: 12),
          ),
        if (players.isEmpty)
          const Text('(없음)', style: TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _RandomMatchupSummary extends StatelessWidget {
  const _RandomMatchupSummary({
    required this.club,
    required this.countController,
  });

  final GameClub club;
  final TextEditingController countController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TeamInfoHeader(label: '선택 구단', club: club),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: _ClubMark(club: club)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'vs',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  const Icon(Icons.casino, size: 48),
                  const SizedBox(height: 8),
                  const Text('랜덤 팀 선정', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('랜덤 팀 개수'),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: countController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                            hintText: '1~1000',
                          ),
                          onEditingComplete: () {
                            final n = int.tryParse(countController.text) ?? 10;
                            countController.text = '${n.clamp(1, 1000)}';
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ResultLogPanel extends StatelessWidget {
  const _ResultLogPanel({required this.lines, required this.emptyHint});

  final List<String> lines;
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text(
              '시뮬레이션 결과',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: lines.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      emptyHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: lines.length,
                    itemBuilder: (context, index) {
                      return SelectableText(
                        lines[index],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.4,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
