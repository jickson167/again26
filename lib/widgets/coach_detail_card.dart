import 'package:flutter/material.dart';

import '../models/coach.dart';
import '../models/formation.dart';
import '../utils/coach_portrait.dart';
import 'game_stat_bar.dart';
import 'leadership_curve_chart.dart';

class CoachDetailCard extends StatelessWidget {
  const CoachDetailCard({
    super.key,
    required this.coach,
    this.formationsById = const {},
  });

  final Coach coach;
  final Map<String, Formation> formationsById;

  @override
  Widget build(BuildContext context) {
    final portraitUrl = CoachPortrait.urlFor(coach.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: '감독 정보',
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.shade800,
                      Colors.red.shade900,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          portraitUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _PortraitFallback(
                            coachId: coach.id,
                            name: coach.name,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _Badge(text: coach.coachType.isNotEmpty ? coach.coachType : '감독'),
                              const SizedBox(width: 6),
                              ...List.generate(
                                coach.effectiveRank,
                                (_) => const Icon(Icons.star, color: Colors.amber, size: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (coach.fakeName != null && coach.fakeName!.isNotEmpty)
                            Text(
                              coach.fakeName!,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          Text(
                            coach.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            coach.id,
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                          const SizedBox(height: 8),
                          _InfoTable(
                            rows: [
                              if (coach.nationality != null) ('국적', coach.nationality!),
                              if (coach.age != null) ('나이', '${coach.age}세'),
                              ('유형', coach.coachType.isNotEmpty ? coach.coachType : '-'),
                              ('랭크', '${coach.effectiveRank}'),
                              ('기본 통솔력', '${coach.baseLeadership}'),
                              (
                                '적합 포메이션',
                                '${coach.unlockFormationCount}개',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 8,
                bottom: 4,
                child: Text(
                  'HEAD COACH',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.12),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        _SectionHeader(
          title: '고유능력',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.deepPurple.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.deepPurple.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            coach.abilityName.isNotEmpty ? coach.abilityName : '-',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.deepPurple.shade900,
                            ),
                          ),
                        ),
                        if (coach.abilityId.isNotEmpty)
                          Chip(
                            label: Text(coach.abilityId),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: Colors.deepPurple.shade100,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      coach.abilityEffect.isNotEmpty ? coach.abilityEffect : '효과 정보 없음',
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GameStatBar(
                label: '통솔력',
                value: coach.baseLeadership,
                max: 100,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 4),
              Text(
                '고유능력 보너스 합계 +${coach.abilityBonusTotal} · 산출 랭크 ${coach.calculatedRank}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        _SectionHeader(
          title: '포메이션 적합도',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FormationFitBlock(
                title: '높음',
                formationIds: coach.fitGood,
                formationsById: formationsById,
                color: Colors.green.shade700,
                background: Colors.green.shade50,
              ),
              const SizedBox(height: 10),
              _FormationFitBlock(
                title: '보통',
                formationIds: coach.fitNormal,
                formationsById: formationsById,
                color: Colors.orange.shade800,
                background: Colors.orange.shade50,
              ),
              const SizedBox(height: 10),
              _FormationFitBlock(
                title: '낮음',
                formationIds: coach.fitBad,
                formationsById: formationsById,
                color: Colors.blueGrey.shade700,
                background: Colors.blueGrey.shade50,
              ),
            ],
          ),
        ),
        _SectionHeader(
          title: '코멘트',
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              coach.comment?.isNotEmpty == true ? coach.comment! : '등록된 코멘트가 없습니다.',
              style: TextStyle(
                height: 1.6,
                color: coach.comment?.isNotEmpty == true ? Colors.black87 : Colors.grey,
              ),
            ),
          ),
        ),
        _SectionHeader(
          title: '통솔력 곡선',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LeadershipCurveChart(values: coach.leadershipCurve),
              const SizedBox(height: 8),
              const Row(
                children: [
                  _CurveLegend(color: Color(0xFFBB86FC), label: '통솔력'),
                  SizedBox(width: 12),
                  Text(
                    '1~18기 · 18기는 0',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FormationFitBlock extends StatelessWidget {
  const _FormationFitBlock({
    required this.title,
    required this.formationIds,
    required this.formationsById,
    required this.color,
    required this.background,
  });

  final String title;
  final List<String> formationIds;
  final Map<String, Formation> formationsById;
  final Color color;
  final Color background;

  String _label(String id) {
    final formation = formationsById[id];
    if (formation != null && formation.name.isNotEmpty) {
      return formation.name;
    }
    return id;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: formationIds.isEmpty
                ? [const Chip(label: Text('-'), visualDensity: VisualDensity.compact)]
                : [
                    for (final id in formationIds)
                      Chip(
                        label: Text(_label(id)),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.white,
                        side: BorderSide(color: color.withValues(alpha: 0.4)),
                      ),
                  ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: const Color(0xFF374151),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: child,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.shade800,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
    );
  }
}

class _InfoTable extends StatelessWidget {
  const _InfoTable({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {0: FixedColumnWidth(88)},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: rows
          .map(
            (row) => TableRow(
              children: [
                Text(row.$1, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text(row.$2, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _PortraitFallback extends StatelessWidget {
  const _PortraitFallback({
    required this.coachId,
    required this.name,
  });

  final String coachId;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name.isNotEmpty ? name.characters.first : '?',
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            coachId,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white54, fontSize: 8),
          ),
        ],
      ),
    );
  }
}

class _CurveLegend extends StatelessWidget {
  const _CurveLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 3, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
