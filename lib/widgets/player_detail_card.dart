import 'package:flutter/material.dart';

import '../models/key_position.dart';
import '../models/player.dart';
import '../models/player_position.dart';
import '../services/nation_flag_service.dart';
import '../utils/profile_badge_labels.dart';
import 'game_stat_bar.dart';
import 'profile_header_badges.dart';
import 'growth_curve_chart.dart';
import 'position_fit_grid.dart';
import 'player_style_chips.dart';
import 'seed_name_chips.dart';

class PlayerDetailCard extends StatefulWidget {
  const PlayerDetailCard({
    super.key,
    required this.player,
    this.keyPositionsById = const {},
    this.styleLabels = const [],
    this.editableComment = false,
    this.onSaveComment,
  });

  final Player player;
  final Map<String, KeyPosition> keyPositionsById;
  final List<String> styleLabels;
  final bool editableComment;
  final Future<void> Function(String comment)? onSaveComment;

  @override
  State<PlayerDetailCard> createState() => _PlayerDetailCardState();
}

class _PlayerDetailCardState extends State<PlayerDetailCard> {
  late TextEditingController _commentController;
  bool _savingComment = false;
  late Future<void> _nationFlagsReady;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(
      text: widget.player.comment ?? '',
    );
    _nationFlagsReady = NationFlagService.instance.ensureLoaded();
  }

  @override
  void didUpdateWidget(covariant PlayerDetailCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player.comment != widget.player.comment) {
      _commentController.text = widget.player.comment ?? '';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _saveComment() async {
    if (widget.onSaveComment == null) {
      return;
    }
    setState(() => _savingComment = true);
    try {
      await widget.onSaveComment!(_commentController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('코멘트가 저장되었습니다.')));
      }
    } finally {
      if (mounted) {
        setState(() => _savingComment = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.player;

    return FutureBuilder<void>(
      future: _nationFlagsReady,
      builder: (context, snapshot) {
        final nation = NationFlagService.instance.resolve(player.nationality);
        final nationalityLabel = nation.displayName.isNotEmpty
            ? nation.displayName
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionHeader(
              title: '선수 정보',
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade800, Colors.red.shade900],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child:
                          player.portraitUrl != null &&
                              player.portraitUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                player.portraitUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) =>
                                    _PortraitFallback(name: player.name),
                              ),
                            )
                          : _PortraitFallback(name: player.name),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProfileHeaderBadges(
                            positionLabel: playerPositionBadgeLabel(player),
                            flagUrl: nation.flagUrl,
                            rank: player.rank,
                          ),
                          const SizedBox(height: 4),
                          PlayerStyleChips(
                            styleLabels: widget.styleLabels,
                            onDarkBackground: true,
                          ),
                          Text(
                            player.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (player.fakeName != null)
                            Text(
                              player.fakeName!,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          const SizedBox(height: 4),
                          SeedNameChips(
                            seedNames: player.displaySeedNames,
                            showLabel: true,
                            onDarkBackground: true,
                          ),
                          const SizedBox(height: 8),
                          _InfoTable(
                            rows: [
                              if (nationalityLabel != null)
                                ('국적', nationalityLabel),
                              if (player.height != null)
                                ('키', '${player.height} cm'),
                              if (player.weight != null)
                                ('몸무게', '${player.weight} kg'),
                              if (player.ageStage != null)
                                ('나이', '${player.ageStage}세'),
                              if (player.peakAge != null)
                                ('전성기 참고', '${player.peakAge}세'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ..._buildRest(player),
          ],
        );
      },
    );
  }

  List<Widget> _buildRest(Player player) {
    return [
      _SectionHeader(
        title: '능력치',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
            final compact = width < 640;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '포지션 적정',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: compact ? 12 : 14,
                        ),
                      ),
                      SizedBox(height: compact ? 4 : 6),
                      PositionFitGrid(
                        positionFit: player.positionFit,
                        compact: compact,
                      ),
                      SizedBox(height: compact ? 4 : 6),
                      Wrap(
                        spacing: compact ? 6 : 8,
                        runSpacing: 4,
                        children: [
                          _LegendDot(
                            color: positionFitColor(2),
                            label: '낮음',
                            compact: compact,
                          ),
                          _LegendDot(
                            color: positionFitColor(5),
                            label: '중간',
                            compact: compact,
                          ),
                          _LegendDot(
                            color: positionFitColor(8),
                            label: '높음',
                            compact: compact,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: compact ? 6 : 16),
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      GameStatBar(
                        label: '스피드',
                        value: player.speed,
                        color: Colors.blue,
                        compact: compact,
                      ),
                      GameStatBar(
                        label: '기술',
                        value: player.technique,
                        color: Colors.green,
                        compact: compact,
                      ),
                      GameStatBar(
                        label: '파워',
                        value: player.power,
                        color: Colors.red,
                        compact: compact,
                      ),
                      GameStatBar(
                        label: '슈팅',
                        value: player.shooting,
                        color: Colors.deepOrange,
                        compact: compact,
                      ),
                      GameStatBar(
                        label: '패스',
                        value: player.passing,
                        color: Colors.teal,
                        compact: compact,
                      ),
                      GameStatBar(
                        label: '활동량',
                        value: player.stamina,
                        color: Colors.brown,
                        compact: compact,
                      ),
                      if (player.position == PlayerPosition.gk ||
                          player.goalkeeper > 0)
                        GameStatBar(
                          label: 'GK',
                          value: player.goalkeeper,
                          color: Colors.purple,
                          compact: compact,
                        ),
                      Divider(height: compact ? 12 : 16),
                      GameStatBar(
                        label: 'PK',
                        value: player.pkAbility,
                        color: Colors.orange,
                        compact: compact,
                      ),
                      GameStatBar(
                        label: 'FK',
                        value: player.fkAbility,
                        color: Colors.orange,
                        compact: compact,
                      ),
                      GameStatBar(
                        label: 'CK',
                        value: player.ckAbility,
                        color: Colors.orange,
                        compact: compact,
                      ),
                      GameStatBar(
                        label: '리더십',
                        value: player.leadership,
                        color: Colors.orange,
                        compact: compact,
                      ),
                      SizedBox(height: compact ? 6 : 8),
                      GameDualSlider(
                        leftLabel: '지성',
                        rightLabel: '감각',
                        leftValue: player.intelligenceValue,
                        rightValue: player.senseValue,
                        compact: compact,
                      ),
                      SizedBox(height: compact ? 6 : 8),
                      GameDualSlider(
                        leftLabel: '개인',
                        rightLabel: '조직',
                        leftValue: player.individualValue,
                        rightValue: player.organizationValue,
                        compact: compact,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      if (player.recommendKeyPositions != null &&
          player.recommendKeyPositions!.isNotEmpty)
        _SectionHeader(
          title: '추천 키포지션',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _parseRecommendations(player.recommendKeyPositions!).map((
              entry,
            ) {
              final kp = widget.keyPositionsById[entry.id];
              return Chip(
                avatar: CircleAvatar(
                  backgroundColor: Colors.green.shade700,
                  child: Text(
                    '${entry.score}',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
                label: Text(kp?.name ?? entry.id),
              );
            }).toList(),
          ),
        ),
      _SectionHeader(
        title: '코멘트',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.editableComment)
              TextField(
                controller: _commentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: '선수 코멘트를 입력하세요',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  player.comment?.isNotEmpty == true
                      ? player.comment!
                      : '등록된 코멘트가 없습니다.',
                  style: TextStyle(
                    color: player.comment?.isNotEmpty == true
                        ? Colors.black87
                        : Colors.grey,
                  ),
                ),
              ),
            if (widget.editableComment) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _savingComment ? null : _saveComment,
                  icon: _savingComment
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('코멘트 저장'),
                ),
              ),
            ],
          ],
        ),
      ),
      _SectionHeader(
        title: '성장 곡선',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GrowthCurveChart(growthType: player.growthType),
            const SizedBox(height: 8),
            const Wrap(
              spacing: 12,
              children: [
                _CurveLegend(color: Colors.blue, label: '스피드'),
                _CurveLegend(color: Colors.green, label: '기술'),
                _CurveLegend(color: Colors.red, label: '파워'),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  List<_RecommendEntry> _parseRecommendations(String raw) {
    return raw
        .split('|')
        .map((part) {
          final pieces = part.split(':');
          return _RecommendEntry(
            id: pieces.first,
            score: pieces.length > 1 ? int.tryParse(pieces[1]) ?? 0 : 0,
          );
        })
        .where((e) => e.id.isNotEmpty)
        .toList();
  }
}

class _RecommendEntry {
  const _RecommendEntry({required this.id, required this.score});
  final String id;
  final int score;
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
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
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

class _InfoTable extends StatelessWidget {
  const _InfoTable({required this.rows});
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {0: FixedColumnWidth(64)},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: rows
          .map(
            (row) => TableRow(
              children: [
                Text(
                  row.$1,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  row.$2,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _PortraitFallback extends StatelessWidget {
  const _PortraitFallback({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        name.isNotEmpty ? name.characters.first : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    this.compact = false,
  });
  final Color color;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 8 : 10,
          height: compact ? 8 : 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: compact ? 3 : 4),
        Text(label, style: TextStyle(fontSize: compact ? 9 : 11)),
      ],
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
