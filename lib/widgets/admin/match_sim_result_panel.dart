import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/match_simulation_dto.dart';
import '../../utils/match_event_commentary_ko.dart';

/// Six-section dry-run match result panel (display only).
class MatchSimResultPanel extends StatefulWidget {
  const MatchSimResultPanel({
    super.key,
    required this.response,
  });

  final MatchSimApiResponse response;

  @override
  State<MatchSimResultPanel> createState() => _MatchSimResultPanelState();
}

class _MatchSimResultPanelState extends State<MatchSimResultPanel> {
  String? _expandedPlayerId;
  bool _jsonExpanded = false;
  int _playerTab = 0;

  @override
  Widget build(BuildContext context) {
    final r = widget.response.result;
    if (r == null) {
      return Text(widget.response.error ?? '결과 없음');
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _banner(context),
        const SizedBox(height: 12),
        _sectionTitle('1. 최종 결과'),
        _finalResult(context, r),
        const SizedBox(height: 16),
        _sectionTitle('2. 팀 경기 통계'),
        _teamStats(context, r),
        const SizedBox(height: 16),
        _sectionTitle('3. 득점 및 주요 사건'),
        _highlights(context, r),
        const SizedBox(height: 16),
        _sectionTitle('4. 선수별 경기 기록'),
        _playerTables(context, r),
        const SizedBox(height: 16),
        _sectionTitle('5. 시간대별 경기 진행'),
        _timeline(context, r),
        const SizedBox(height: 16),
        _sectionTitle('6. 원본 JSON'),
        _jsonBlock(context),
      ],
    );
  }

  Widget _banner(BuildContext context) {
    return MaterialBanner(
      content: Text(
        widget.response.warning ??
            '테스트 경기 · DB 저장 안 됨 · 선수 통산 기록 반영 안 됨',
      ),
      leading: const Icon(Icons.science_outlined),
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      actions: const [SizedBox.shrink()],
    );
  }

  Widget _sectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }

  Widget _finalResult(BuildContext context, MatchSimulationResultDto r) {
    final home = r.homeClubName ?? r.homeClubId;
    final away = r.awayClubName ?? r.awayClubId;
    final String outcome;
    if (r.homeScore > r.awayScore) {
      outcome = '$home 승 (홈)';
    } else if (r.awayScore > r.homeScore) {
      outcome = '$away 승 (원정)';
    } else {
      outcome = '무승부';
    }
    final mvp = r.playerName(r.mvpPlayerId) ?? r.mvpPlayerId ?? '-';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '홈  $home  ${r.homeScore} : ${r.awayScore}  $away  원정',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('결과: $outcome'),
            Text('MVP: $mvp'),
            Text('Seed: ${r.seed}'),
            Text('Engine: v${r.simulationVersion}'),
          ],
        ),
      ),
    );
  }

  Widget _teamStats(BuildContext context, MatchSimulationResultDto r) {
    final s = r.statistics;
    final rows = <(String, String, String)>[
      ('점유율', '${s.homePossession}%', '${s.awayPossession}%'),
      ('슈팅', '${s.homeShots}', '${s.awayShots}'),
      ('유효 슈팅', '${s.homeShotsOnTarget}', '${s.awayShotsOnTarget}'),
      ('득점', '${s.homeGoals}', '${s.awayGoals}'),
      ('도움', '${s.homeAssists}', '${s.awayAssists}'),
      ('코너킥', '${s.homeCorners}', '${s.awayCorners}'),
      ('프리킥', '${s.homeFreeKicks}', '${s.awayFreeKicks}'),
      ('오프사이드', '${s.homeOffsides}', '${s.awayOffsides}'),
      ('파울', '${s.homeFouls}', '${s.awayFouls}'),
      ('경고', '${s.homeYellowCards}', '${s.awayYellowCards}'),
      ('퇴장', '${s.homeRedCards}', '${s.awayRedCards}'),
      ('선방', '${s.homeSaves}', '${s.awaySaves}'),
      ('패스 시도', '${s.homePassesAttempted}', '${s.awayPassesAttempted}'),
      ('패스 성공', '${s.homePassesCompleted}', '${s.awayPassesCompleted}'),
      (
        '패스 성공률',
        '${s.homePassCompletionRate.toStringAsFixed(1)}%',
        '${s.awayPassCompletionRate.toStringAsFixed(1)}%',
      ),
      (
        'xG',
        s.homeExpectedGoals.toStringAsFixed(2),
        s.awayExpectedGoals.toStringAsFixed(2),
      ),
    ];
    return Card(
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.4),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
        },
        children: [
          TableRow(
            children: [
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('항목', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  r.homeClubName ?? '홈',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  r.awayClubName ?? '원정',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          for (final row in rows)
            TableRow(
              children: [
                Padding(padding: const EdgeInsets.all(8), child: Text(row.$1)),
                Padding(padding: const EdgeInsets.all(8), child: Text(row.$2)),
                Padding(padding: const EdgeInsets.all(8), child: Text(row.$3)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _highlights(BuildContext context, MatchSimulationResultDto r) {
    final goals = r.events.where(
      (e) => e.type == 'goal' || e.type == 'penalty_scored',
    );
    final cards = r.events.where(
      (e) => e.type == 'yellow_card' || e.type == 'red_card',
    );
    final subs = r.events.where((e) => e.type == 'substitution');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('득점', style: TextStyle(fontWeight: FontWeight.w600)),
            for (final e in goals)
              Text(
                "${e.matchMinute}' "
                "[${e.side == 'home' ? (r.homeClubName ?? '홈') : (r.awayClubName ?? '원정')}] "
                "${r.playerName(e.primaryPlayerId) ?? '?'}"
                "${e.secondaryPlayerId != null ? ' (${r.playerName(e.secondaryPlayerId)})' : ''}",
              ),
            if (goals.isEmpty) const Text('-'),
            const SizedBox(height: 8),
            const Text('카드', style: TextStyle(fontWeight: FontWeight.w600)),
            for (final e in cards)
              Text(
                "${e.matchMinute}' ${r.playerName(e.primaryPlayerId)} "
                "${e.type == 'red_card' ? '퇴장' : '경고'}",
              ),
            if (cards.isEmpty) const Text('-'),
            const SizedBox(height: 8),
            const Text('교체', style: TextStyle(fontWeight: FontWeight.w600)),
            for (final e in subs)
              Text(
                "${e.matchMinute}' ${r.playerName(e.substitutedOutPlayerId)} OUT → "
                "${r.playerName(e.substitutedInPlayerId)} IN",
              ),
            if (subs.isEmpty) const Text('-'),
          ],
        ),
      ),
    );
  }

  Widget _playerTables(BuildContext context, MatchSimulationResultDto r) {
    final home = r.playerMatchStats.where((p) => p.teamId == r.homeClubId).toList();
    final away = r.playerMatchStats.where((p) => p.teamId == r.awayClubId).toList();
    return Column(
      children: [
        SegmentedButton<int>(
          segments: [
            ButtonSegment(
              value: 0,
              label: Text(r.homeClubName ?? '홈'),
            ),
            ButtonSegment(
              value: 1,
              label: Text(r.awayClubName ?? '원정'),
            ),
          ],
          selected: {_playerTab},
          onSelectionChanged: (s) => setState(() => _playerTab = s.first),
        ),
        const SizedBox(height: 8),
        _playerList(_playerTab == 0 ? home : away, r),
      ],
    );
  }

  Widget _playerList(List<PlayerMatchStatsDto> players, MatchSimulationResultDto r) {
    return Card(
      child: Column(
        children: [
          for (final p in players) ...[
            ListTile(
              dense: true,
              title: Text(
                '${p.name ?? p.playerId} (${p.position})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                p.isGk
                    ? '평점 ${p.rating.toStringAsFixed(1)} · ${p.minutesPlayed}분 · '
                        '선방 ${p.saves} · 실점 ${p.goalsConceded} · '
                        '경고 ${p.yellowCards} · 퇴장 ${p.redCards}'
                    : '평점 ${p.rating.toStringAsFixed(1)} · ${p.minutesPlayed}분 · '
                        'G${p.goals} A${p.assists} · '
                        '슈팅 ${p.shots}/${p.shotsOnTarget} · '
                        '패스 ${p.passesCompleted}/${p.passesAttempted} · '
                        '코너 ${p.cornersTaken} · 파울 ${p.foulsCommitted} · '
                        '경고 ${p.yellowCards} · 퇴장 ${p.redCards} · '
                        '체력 ${(p.staminaUsed * 100).round()}%',
              ),
              trailing: Icon(
                _expandedPlayerId == p.playerId
                    ? Icons.expand_less
                    : Icons.expand_more,
              ),
              onTap: () => setState(() {
                _expandedPlayerId =
                    _expandedPlayerId == p.playerId ? null : p.playerId;
              }),
            ),
            if (_expandedPlayerId == p.playerId)
              _playerDetail(p, r),
            const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  Widget _playerDetail(PlayerMatchStatsDto p, MatchSimulationResultDto r) {
    final involvements = r.events.where(
      (e) =>
          e.primaryPlayerId == p.playerId ||
          e.secondaryPlayerId == p.playerId ||
          e.goalkeeperId == p.playerId ||
          e.fouledPlayerId == p.playerId,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '공격: 골 ${p.goals} 도움 ${p.assists} 슈팅 ${p.shots} '
            '(유효 ${p.shotsOnTarget} / 빗나감 ${p.shotsOffTarget}) '
            '키패스 ${p.keyPasses} 드리블성공 ${p.dribblesCompleted}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            '패스: ${p.passesCompleted}/${p.passesAttempted} · '
            '세트피스: 코너 ${p.cornersTaken} FK ${p.freeKicksTaken} '
            'PK ${p.penaltiesScored}/${p.penaltiesTaken}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            '수비: 태클승 ${p.tacklesWon} 인터셉트 ${p.interceptions} '
            '클리어 ${p.clearances} 선방 ${p.saves} 실점 ${p.goalsConceded}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            '징계: 파울 ${p.foulsCommitted}/${p.foulsSuffered} '
            '경고 ${p.yellowCards} 퇴장 ${p.redCards} · '
            '체력소모 ${(p.staminaUsed * 100).round()}%',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          const Text('이벤트 참여', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          for (final e in involvements.take(12))
            Text(
              MatchEventCommentaryKo.line(
                e,
                r.playerName,
                matchSeed: r.seed,
                homeName: r.homeClubName,
                awayName: r.awayClubName,
              ),
              style: const TextStyle(fontSize: 11),
            ),
        ],
      ),
    );
  }

  Widget _timeline(BuildContext context, MatchSimulationResultDto r) {
    final lines = MatchEventCommentaryKo.filterForTimeline(r.events);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final e in lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  MatchEventCommentaryKo.line(
                    e,
                    r.playerName,
                    matchSeed: r.seed,
                    homeName: r.homeClubName,
                    awayName: r.awayClubName,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _jsonBlock(BuildContext context) {
    final raw = widget.response.raw ?? {};
    final text = const JsonEncoder.withIndent('  ').convert(raw);
    return Card(
      child: ExpansionTile(
        initiallyExpanded: _jsonExpanded,
        onExpansionChanged: (v) => setState(() => _jsonExpanded = v),
        title: const Text('원본 JSON 보기'),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: text));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('JSON 복사됨')),
                  );
                }
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('복사'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              text,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
