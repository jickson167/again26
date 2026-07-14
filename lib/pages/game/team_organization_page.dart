import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../models/club_player.dart';
import '../../models/formation.dart';
import '../../models/game_club.dart';
import '../../models/player.dart';
import '../../models/player_match_stats.dart';
import '../../models/player_position.dart';
import '../../models/player_style.dart';
import '../../services/app_services.dart';
import '../../services/nation_flag_service.dart';
import '../../utils/coach_portrait.dart';
import '../../utils/field_zone_layout.dart';
import '../../utils/formation_layout_grid.dart';
import '../../utils/formation_shape.dart';
import '../../utils/player_portrait.dart';
import '../../utils/profile_badge_labels.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/game_stat_bar.dart';
import '../../widgets/player_style_chips.dart';
import '../../widgets/profile_header_badges.dart';
import 'team_org_bg_config.dart';

/// PK / FK / CK / Cap. 역할 마크·버튼 공통 색상.
Color skillRoleColor(String role) {
  return switch (role) {
    'PK' || 'pk' => const Color(0xFFDC2626),
    'FK' || 'fk' => const Color(0xFF2563EB),
    'CK' || 'ck' => const Color(0xFFEA580C),
    'Cap.' || 'cap' => const Color(0xFF84CC16),
    _ => const Color(0xFF6B7280),
  };
}

/// 팀 조직 편성 화면 (선발 피치 · 후보 · 능력치/역할 · 감독/포메이션/저장)
class TeamOrganizationView extends StatefulWidget {
  const TeamOrganizationView({
    super.key,
    required this.club,
    required this.services,
    required this.isDevTestMode,
    required this.onClubUpdated,
    this.compact = false,
  });

  final GameClub club;
  final AppServices services;
  final bool isDevTestMode;
  final ValueChanged<GameClub> onClubUpdated;
  final bool compact;

  @override
  State<TeamOrganizationView> createState() => _TeamOrganizationViewState();
}

class _TeamOrganizationViewState extends State<TeamOrganizationView>
    with TickerProviderStateMixin {
  static const _swapDuration = Duration(milliseconds: 450);

  final GlobalKey _pitchPanelKey = GlobalKey();
  final GlobalKey _bgStackKey = GlobalKey();
  final GlobalKey _benchZoneKey = GlobalKey();
  final Map<int, GlobalKey> _slotKeys = {};

  late List<ClubPlayer> _squad;
  late Formation _formation;
  String? _pkPlayerId;
  String? _fkPlayerId;
  String? _ckPlayerId;
  String? _captainPlayerId;
  /// 마우스 호버(또는 터치 프레스 고정) — 외곽선 · 최적 포지션 패널
  String? _hoveredPlayerId;
  /// 클릭/프레스로 연 우측 선수정보 (호버가 사라져도 유지)
  String? _inspectedPlayerId;
  bool _saving = false;
  List<Formation> _formations = const [];
  bool _loadingFormations = true;
  Map<String, PlayerStyle> _stylesById = const {};

  /// 드롭으로 즉시 자리 잡는 선수 (이동 애니메이션 생략).
  final Set<String> _instantMovePlayerIds = {};
  /// 선발↔후보 등 교차 비행 중 슬롯에서 숨길 선수.
  final Set<String> _hiddenDuringFlight = {};
  List<_SwapFlight>? _swapFlights;
  _PlayerDragSession? _drag;
  AnimationController? _snapBackController;
  AnimationController? _flightController;

  @override
  void initState() {
    super.initState();
    _syncFromClub(widget.club);
    _loadFormations();
    _loadStyles();
    NationFlagService.instance.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _snapBackController?.dispose();
    _flightController?.dispose();
    super.dispose();
  }

  GlobalKey _slotKey(int positionIndex) {
    return _slotKeys.putIfAbsent(
      positionIndex,
      () => GlobalKey(debugLabel: 'slot-$positionIndex'),
    );
  }

  Duration _moveDurationFor(String playerId) {
    if (_instantMovePlayerIds.contains(playerId)) {
      return Duration.zero;
    }
    return _swapDuration;
  }

  @override
  void didUpdateWidget(covariant TeamOrganizationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.club.id != widget.club.id) {
      _syncFromClub(widget.club);
    }
  }

  void _syncFromClub(GameClub club) {
    _squad = [for (final cp in club.squad) cp.copyWith()];
    _formation = club.formation;
    _pkPlayerId = club.pkPlayerId;
    _fkPlayerId = club.fkPlayerId;
    _ckPlayerId = club.ckPlayerId;
    _captainPlayerId = club.captainPlayerId;
    _ensureRolesOnStarters();
  }

  List<Player> get _starterPlayers => [
        for (final cp in _squad)
          if (cp.isStarter) cp.player,
      ];

  ClubPlayer? _clubPlayerById(String playerId) {
    for (final cp in _squad) {
      if (cp.playerId == playerId) return cp;
    }
    return null;
  }

  /// 역할 보유자가 후보이거나 비어 있으면 선발 기준으로 채움 (초기/복구용).
  /// 선발↔후보 스왑 시 역할 이전에는 쓰지 않는다.
  void _ensureRolesOnStarters() {
    final filled = GameClub.ensureRolesOnStarters(
      starters: _starterPlayers,
      pkPlayerId: _pkPlayerId,
      fkPlayerId: _fkPlayerId,
      ckPlayerId: _ckPlayerId,
      captainPlayerId: _captainPlayerId,
    );
    if (filled == null) return;
    _pkPlayerId = filled.pkPlayerId;
    _fkPlayerId = filled.fkPlayerId;
    _ckPlayerId = filled.ckPlayerId;
    _captainPlayerId = filled.captainPlayerId;
  }

  Future<void> _loadFormations() async {
    try {
      final list = await widget.services.formationService.fetchAll();
      if (!mounted) return;
      setState(() {
        _formations = list;
        _loadingFormations = false;
        for (final f in list) {
          if (f.id == _formation.id) {
            _formation = f;
            break;
          }
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingFormations = false);
    }
  }

  Future<void> _loadStyles() async {
    try {
      final styles = await widget.services.playerStyleService.fetchAll();
      if (!mounted) return;
      setState(() {
        _stylesById = {for (final s in styles) s.id: s};
      });
    } catch (_) {}
  }

  ClubPlayer? _at(int positionIndex) {
    for (final cp in _squad) {
      if (cp.positionIndex == positionIndex) return cp;
    }
    return null;
  }

  Player? get _inspectedPlayer {
    final id = _inspectedPlayerId;
    if (id == null) return null;
    for (final cp in _squad) {
      if (cp.playerId == id) return cp.player;
    }
    return null;
  }

  Player? get _hoveredPlayer {
    final id = _hoveredPlayerId;
    if (id == null) return null;
    for (final cp in _squad) {
      if (cp.playerId == id) return cp.player;
    }
    return null;
  }

  int get _teamPower {
    var sum = 0;
    for (final cp in _squad) {
      if (!cp.isStarter) continue;
      final p = cp.player;
      sum += p.speed +
          p.power +
          p.technique +
          p.shooting +
          p.passing +
          p.stamina;
    }
    return sum;
  }

  void _swapPositions(
    int fromIndex,
    int toIndex, {
    Set<String>? instantPlayerIds,
  }) {
    if (fromIndex == toIndex) return;
    final a = _at(fromIndex);
    final b = _at(toIndex);
    if (a == null || b == null) return;

    final aWasStarter = fromIndex >= 1 && fromIndex <= 11;
    final bWasStarter = toIndex >= 1 && toIndex <= 11;
    // 후보가 끼면 AnimatedPositioned가 이어지지 않으므로 오버레이 비행
    final needsFlight = !aWasStarter || !bWasStarter;

    final fromRect = _globalRectFor(_slotKey(fromIndex));
    final toRect = _globalRectFor(_slotKey(toIndex));
    List<_SwapFlight>? flights;
    if (needsFlight && fromRect != null && toRect != null) {
      flights = [
        _SwapFlight(
          playerId: a.playerId,
          player: a.player,
          roles: _rolesFor(a.playerId),
          avatarRadius: 26,
          cardSize: Size(fromRect.width, fromRect.height),
          startTopLeft: _stackLocal(fromRect.topLeft),
          endTopLeft: _stackLocal(toRect.topLeft),
        ),
        _SwapFlight(
          playerId: b.playerId,
          player: b.player,
          roles: _rolesFor(b.playerId),
          avatarRadius: 26,
          cardSize: Size(toRect.width, toRect.height),
          startTopLeft: _stackLocal(toRect.topLeft),
          endTopLeft: _stackLocal(fromRect.topLeft),
        ),
      ];
    }

    final instant = needsFlight
        ? {a.playerId, b.playerId}
        : (instantPlayerIds ?? {a.playerId});

    setState(() {
      _instantMovePlayerIds
        ..clear()
        ..addAll(instant);
      if (flights != null) {
        _hiddenDuringFlight
          ..clear()
          ..addAll({a.playerId, b.playerId});
        _swapFlights = flights;
      }
      _squad = [
        for (final cp in _squad)
          if (cp.playerId == a.playerId)
            cp.copyWith(positionIndex: toIndex)
          else if (cp.playerId == b.playerId)
            cp.copyWith(positionIndex: fromIndex)
          else
            cp,
      ];
      // 선발↔후보: 내려간 선수의 역할을 올라온 선수에게 이전 (능력치 재배정 아님)
      if (aWasStarter && !bWasStarter) {
        _applyRoleTransfer(from: a.playerId, to: b.playerId);
      } else if (!aWasStarter && bWasStarter) {
        _applyRoleTransfer(from: b.playerId, to: a.playerId);
      }
    });

    if (flights != null) {
      _runSwapFlightAnimation(flights);
    } else {
      Future<void>.delayed(_swapDuration, () {
        if (!mounted) return;
        setState(() => _instantMovePlayerIds.clear());
      });
    }
  }

  void _runSwapFlightAnimation(List<_SwapFlight> flights) {
    _flightController?.stop();
    _flightController?.dispose();
    final controller = AnimationController(
      vsync: this,
      duration: _swapDuration,
    );
    _flightController = controller;
    final animations = [
      for (final f in flights)
        Tween<Offset>(begin: f.startTopLeft, end: f.endTopLeft).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeInOut),
        ),
    ];

    void tick() {
      if (!mounted || _swapFlights != flights) return;
      setState(() {
        for (var i = 0; i < flights.length; i++) {
          flights[i].topLeft = animations[i].value;
        }
      });
    }

    // 시작 위치 동기화
    for (final f in flights) {
      f.topLeft = f.startTopLeft;
    }

    animations.first.addListener(tick);
    controller.forward().whenComplete(() {
      animations.first.removeListener(tick);
      controller.dispose();
      if (_flightController == controller) {
        _flightController = null;
      }
      if (!mounted) return;
      setState(() {
        if (_swapFlights == flights) {
          _swapFlights = null;
          _hiddenDuringFlight.clear();
          _instantMovePlayerIds.clear();
        }
      });
    });
  }

  void _applyRoleTransfer({required String from, required String to}) {
    if (_pkPlayerId == from) _pkPlayerId = to;
    if (_fkPlayerId == from) _fkPlayerId = to;
    if (_ckPlayerId == from) _ckPlayerId = to;
    if (_captainPlayerId == from) _captainPlayerId = to;
  }

  Rect? _globalRectFor(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Offset _stackLocal(Offset global) {
    final box = _bgStackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return global;
    return box.globalToLocal(global);
  }

  Offset _clampFeedbackTopLeft(Offset rawTopLeft, Size cardSize) {
    final pitch = _globalRectFor(_pitchPanelKey);
    final bench = _globalRectFor(_benchZoneKey);
    Rect? play;
    if (pitch != null && bench != null) {
      play = pitch.expandToInclude(bench);
    } else {
      play = pitch ?? bench;
    }
    if (play == null) return rawTopLeft;
    final maxLeft = math.max(play.left, play.right - cardSize.width);
    final maxTop = math.max(play.top, play.bottom - cardSize.height);
    return Offset(
      rawTopLeft.dx.clamp(play.left, maxLeft),
      rawTopLeft.dy.clamp(play.top, maxTop),
    );
  }

  int? _hitSlotIndex(Offset global, {required int excludeIndex}) {
    int? best;
    var bestArea = double.infinity;
    for (final entry in _slotKeys.entries) {
      if (entry.key == excludeIndex) continue;
      final rect = _globalRectFor(entry.value);
      if (rect == null || !rect.contains(global)) continue;
      final area = rect.width * rect.height;
      if (area < bestArea) {
        bestArea = area;
        best = entry.key;
      }
    }
    return best;
  }

  void _startPlayerDrag(_PlayerDragSession session) {
    _snapBackController?.stop();
    _snapBackController?.dispose();
    _snapBackController = null;
    setState(() {
      _drag = session;
      _hoveredPlayerId = null; // 드래그 시작 시 최적위치 패널 숨김
    });
  }

  void _updatePlayerDrag(Offset globalPointer) {
    final drag = _drag;
    if (drag == null || drag.snappingBack) return;
    final raw = globalPointer - drag.pointerOffsetInCard;
    final clamped = _clampFeedbackTopLeft(raw, drag.cardSize);
    setState(() {
      drag.feedbackTopLeft = clamped;
    });
  }

  void _endPlayerDrag(Offset globalPointer) {
    final drag = _drag;
    if (drag == null) return;
    if (drag.snappingBack) return;

    final raw = globalPointer - drag.pointerOffsetInCard;
    final clamped = _clampFeedbackTopLeft(raw, drag.cardSize);
    final dropPoint =
        clamped + Offset(drag.cardSize.width / 2, drag.cardSize.height / 2);
    final target = _hitSlotIndex(dropPoint, excludeIndex: drag.fromIndex);

    if (target != null && _at(target) != null) {
      final from = drag.fromIndex;
      setState(() {
        _drag = null;
      });
      // 두 선수 모두 이동 애니메이션 재생
      _swapPositions(from, target, instantPlayerIds: const {});
      return;
    }

    _animateSnapBack(drag);
  }

  void _cancelPlayerDrag() {
    final drag = _drag;
    if (drag == null || drag.snappingBack) return;
    _animateSnapBack(drag);
  }

  void _animateSnapBack(_PlayerDragSession drag) {
    drag.snappingBack = true;
    _snapBackController?.dispose();
    final controller = AnimationController(
      vsync: this,
      duration: _swapDuration,
    );
    final animation = Tween<Offset>(
      begin: drag.feedbackTopLeft,
      end: drag.originTopLeft,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
    _snapBackController = controller;

    void tick() {
      if (!mounted || _drag != drag) return;
      setState(() => drag.feedbackTopLeft = animation.value);
    }

    animation.addListener(tick);
    controller.forward().whenComplete(() {
      animation.removeListener(tick);
      controller.dispose();
      if (_snapBackController == controller) {
        _snapBackController = null;
      }
      if (mounted) {
        setState(() {
          if (_drag == drag) {
            _drag = null;
          }
        });
      }
    });
  }

  void _setHoveredPlayer(String? playerId) {
    if (_drag != null) return; // 드래그 중에는 최적위치 패널/호버 미적용
    if (_hoveredPlayerId == playerId) return;
    setState(() => _hoveredPlayerId = playerId);
  }

  void _clearHoveredPlayer(String playerId) {
    if (_drag != null) return;
    if (_hoveredPlayerId != playerId) return;
    setState(() => _hoveredPlayerId = null);
  }

  void _inspectPlayer(String playerId) {
    if (_inspectedPlayerId == playerId) return;
    setState(() => _inspectedPlayerId = playerId);
  }

  /// 터치/스타일러스 프레스: 외곽선·시너지·선수정보를 즉시 함께 표시.
  void _touchPressPlayer(String playerId) {
    setState(() {
      _hoveredPlayerId = playerId;
      _inspectedPlayerId = playerId;
    });
  }

  /// 선발에게 역할 이전. 본인이 이미 맡은 역할은 해제되지 않음.
  void _assignRole(String role) {
    final selected = _inspectedPlayerId;
    if (selected == null) return;
    final cp = _clubPlayerById(selected);
    if (cp == null || !cp.isStarter) return;

    final current = switch (role) {
      'pk' => _pkPlayerId,
      'fk' => _fkPlayerId,
      'ck' => _ckPlayerId,
      'cap' => _captainPlayerId,
      _ => null,
    };
    if (current == selected) return;

    setState(() {
      switch (role) {
        case 'pk':
          _pkPlayerId = selected;
        case 'fk':
          _fkPlayerId = selected;
        case 'ck':
          _ckPlayerId = selected;
        case 'cap':
          _captainPlayerId = selected;
      }
    });
  }

  /// 선발만 역할 마크 표시 (PK → FK → CK → Cap. 순서).
  List<String> _rolesFor(String playerId) {
    final cp = _clubPlayerById(playerId);
    if (cp == null || !cp.isStarter) return const [];
    return [
      if (_pkPlayerId == playerId) 'PK',
      if (_fkPlayerId == playerId) 'FK',
      if (_ckPlayerId == playerId) 'CK',
      if (_captainPlayerId == playerId) 'Cap.',
    ];
  }

  GameClub _buildDraftClub() {
    return widget.club.copyWith(
      formation: _formation,
      squad: _squad,
      pkPlayerId: _pkPlayerId,
      fkPlayerId: _fkPlayerId,
      ckPlayerId: _ckPlayerId,
      captainPlayerId: _captainPlayerId,
      clearPkPlayerId: _pkPlayerId == null,
      clearFkPlayerId: _fkPlayerId == null,
      clearCkPlayerId: _ckPlayerId == null,
      clearCaptainPlayerId: _captainPlayerId == null,
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final draft = _buildDraftClub();
      final GameClub saved;
      if (widget.isDevTestMode) {
        saved = await widget.services.devTestUserService
            .updateTeamOrganization(club: draft);
      } else {
        saved = await widget.services.gameClubService
            .updateTeamOrganization(club: draft);
      }
      widget.onClubUpdated(saved);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('저장 완료'),
          content: const Text('팀 조직이 저장되었습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: compact
                ? SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildMainRow(compact: true),
                        const SizedBox(height: 8),
                        SizedBox(height: 420, child: _buildStatsPanel()),
                      ],
                    ),
                  )
                : _buildMainRow(compact: false),
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  /// 선발 | 후보(세로 2열) | 선수정보 — 배경은 선발 패널에 경기장 영역 정렬
  Widget _buildMainRow({required bool compact}) {
    final pitch = _StarterPitchPanel(
      key: _pitchPanelKey,
      formationName: _formation.name,
      layoutOutfield: _formation.layoutOutfield,
      squad: _squad,
      teamPower: _teamPower,
      hoveredPlayerId: _hoveredPlayerId,
      hoveredPositionFit: _drag != null ? null : _hoveredPlayer?.positionFit,
      rolesFor: _rolesFor,
      slotKeyFor: _slotKey,
      draggingPlayerId: _drag?.playerId,
      dragActive: _drag != null,
      hiddenPlayerIds: _hiddenDuringFlight,
      moveDurationFor: _moveDurationFor,
      onHoverPlayer: _setHoveredPlayer,
      onHoverExitPlayer: _clearHoveredPlayer,
      onInspectPlayer: _inspectPlayer,
      onTouchPressPlayer: _touchPressPlayer,
      onDragStart: _startPlayerDrag,
      onDragUpdate: _updatePlayerDrag,
      onDragEnd: _endPlayerDrag,
      onDragCancel: _cancelPlayerDrag,
      transparentField: true,
      hideDrawnLines: TeamOrgBgConfig.hideDrawnPitchLines,
    );
    final bench = _BenchZone(
      key: _benchZoneKey,
      squad: _squad,
      hoveredPlayerId: _hoveredPlayerId,
      rolesFor: _rolesFor,
      slotKeyFor: _slotKey,
      draggingPlayerId: _drag?.playerId,
      dragActive: _drag != null,
      hiddenPlayerIds: _hiddenDuringFlight,
      moveDurationFor: _moveDurationFor,
      onHoverPlayer: _setHoveredPlayer,
      onHoverExitPlayer: _clearHoveredPlayer,
      onInspectPlayer: _inspectPlayer,
      onTouchPressPlayer: _touchPressPlayer,
      onDragStart: _startPlayerDrag,
      onDragUpdate: _updatePlayerDrag,
      onDragEnd: _endPlayerDrag,
      onDragCancel: _cancelPlayerDrag,
      transparent: true,
    );
    final stats = _buildStatsPanel(transparent: true);

    final row = compact
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 210, height: 240, child: pitch),
              const SizedBox(width: 6),
              SizedBox(width: 140, height: 240, child: bench),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: pitch),
              const SizedBox(width: 6),
              SizedBox(width: 148, child: bench),
              const SizedBox(width: 6),
              Expanded(flex: 3, child: stats),
            ],
          );

    final drag = _drag;
    Offset? feedbackLocal;
    if (drag != null) {
      feedbackLocal = _stackLocal(drag.feedbackTopLeft);
    }

    final stack = Stack(
      key: _bgStackKey,
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(
          child: _AlignedTeamOrgBackground(
            stackKey: _bgStackKey,
            pitchKey: _pitchPanelKey,
            compact: compact,
          ),
        ),
        row,
        if (drag != null && feedbackLocal != null)
          Positioned(
            left: feedbackLocal.dx,
            top: feedbackLocal.dy,
            width: drag.cardSize.width,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.45,
                child: _PlayerCard(
                  player: drag.player,
                  roles: const [],
                  selected: false,
                  showMeta: false,
                  avatarRadius: drag.avatarRadius,
                  width: drag.cardSize.width,
                ),
              ),
            ),
          ),
        if (_swapFlights != null)
          for (final flight in _swapFlights!)
            Positioned(
              left: flight.topLeft.dx,
              top: flight.topLeft.dy,
              width: flight.cardSize.width,
              child: IgnorePointer(
                child: _PlayerCard(
                  player: flight.player,
                  roles: flight.roles,
                  selected: false,
                  avatarRadius: flight.avatarRadius,
                  width: flight.cardSize.width,
                ),
              ),
            ),
      ],
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: compact ? SizedBox(height: 240, child: stack) : stack,
    );
  }

  Widget _buildStatsPanel({bool transparent = false}) {
    final player = _inspectedPlayer;
    final matchStats = player == null
        ? PlayerMatchStats.zeros
        : widget.club.matchStatsFor(player.id);
    final styleLabels = player == null
        ? const <String>[]
        : resolveStyleLabels(
            styleIds: player.styleIds,
            stylesById: _stylesById,
          );
    final flagUrl = player == null
        ? null
        : NationFlagService.instance.resolve(player.nationality).flagUrl;
    final selectedCp =
        player == null ? null : _clubPlayerById(player.id);
    final rolesEnabled = selectedCp?.isStarter ?? false;

    return Container(
      decoration: BoxDecoration(
        color: transparent
            ? Colors.black.withValues(alpha: 0.35)
            : const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black45),
      ),
      padding: const EdgeInsets.all(10),
      child: player == null
          ? const Center(
              child: Text(
                '선수를 선택하세요',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : Theme(
              data: ThemeData.dark(useMaterial3: true),
              child: _PlayerStatsPanel(
                player: player,
                matchStats: matchStats,
                styleLabels: styleLabels,
                flagUrl: flagUrl,
                rolesEnabled: rolesEnabled,
                pkSelected: _pkPlayerId == player.id,
                fkSelected: _fkPlayerId == player.id,
                ckSelected: _ckPlayerId == player.id,
                capSelected: _captainPlayerId == player.id,
                onAssignRole: _assignRole,
              ),
            ),
    );
  }

  Widget _buildBottomBar() {
    final coach = widget.club.coach;
    final leadership = coach.baseLeadership;
    final curveMax = coach.leadershipCurve.isEmpty
        ? leadership
        : coach.leadershipCurve.reduce(math.max);
    final portraitUrl = CoachPortrait.expectedUrl(coach);
    // 바 높이보다 크게 — 하단 라인에 발을 맞추고 위로는 넘침 허용
    const coachImageHeight = 96.0;
    const coachSlotWidth = 64.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black45),
      ),
      clipBehavior: Clip.none,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                const SizedBox(width: coachSlotWidth + 8),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        coach.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '통솔력 $leadership / $curveMax',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '포메이션변경',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: _loadingFormations
                            ? const SizedBox(
                                height: 32,
                                child: Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              )
                            : DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _formations
                                          .any((f) => f.id == _formation.id)
                                      ? _formation.id
                                      : null,
                                  hint: Text(
                                    _formation.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  items: [
                                    for (final f in _formations)
                                      DropdownMenuItem(
                                        value: f.id,
                                        child: Text(
                                          f.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                  ],
                                  onChanged: (id) {
                                    if (id == null) return;
                                    final next = _formations
                                        .where((f) => f.id == id)
                                        .firstOrNull;
                                    if (next == null) return;
                                    setState(() => _formation = next);
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            '팀 조직 결정',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 10,
            bottom: 0,
            child: portraitUrl.isNotEmpty
                ? Image.network(
                    portraitUrl,
                    height: coachImageHeight,
                    alignment: Alignment.bottomCenter,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, _, _) => SizedBox(
                      width: coachSlotWidth,
                      height: 44,
                      child: Center(
                        child: Text(
                          coach.name.isNotEmpty
                              ? coach.name.characters.first
                              : '?',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                : SizedBox(
                    width: coachSlotWidth,
                    height: 44,
                    child: Center(
                      child: Text(
                        coach.name.isNotEmpty
                            ? coach.name.characters.first
                            : '?',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AlignedTeamOrgBackground extends StatefulWidget {
  const _AlignedTeamOrgBackground({
    required this.stackKey,
    required this.pitchKey,
    required this.compact,
  });

  final GlobalKey stackKey;
  final GlobalKey pitchKey;
  final bool compact;

  @override
  State<_AlignedTeamOrgBackground> createState() =>
      _AlignedTeamOrgBackgroundState();
}

class _AlignedTeamOrgBackgroundState extends State<_AlignedTeamOrgBackground> {
  Rect? _pitchInStack;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(covariant _AlignedTeamOrgBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    if (!mounted) return;
    final stackBox =
        widget.stackKey.currentContext?.findRenderObject() as RenderBox?;
    final pitchBox =
        widget.pitchKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null || pitchBox == null || !stackBox.hasSize) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pitchInStack == null) _measure();
      });
      return;
    }
    final stackOrigin = stackBox.localToGlobal(Offset.zero);
    final pitchOrigin = pitchBox.localToGlobal(Offset.zero);
    final next = Rect.fromLTWH(
      pitchOrigin.dx - stackOrigin.dx,
      pitchOrigin.dy - stackOrigin.dy,
      pitchBox.size.width,
      pitchBox.size.height,
    );
    if (_pitchInStack != next) {
      setState(() => _pitchInStack = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pitch = _pitchInStack;
    final region = TeamOrgBgConfig.pitchRegionInImage;
    final nudge = widget.compact
        ? TeamOrgBgConfig.compactNudge
        : TeamOrgBgConfig.desktopNudge;
    final scale = widget.compact
        ? TeamOrgBgConfig.compactScale
        : TeamOrgBgConfig.desktopScale;

    if (pitch == null ||
        pitch.width <= 0 ||
        pitch.height <= 0 ||
        region.width <= 0 ||
        region.height <= 0) {
      return const ColoredBox(
        color: Color(0xFF166534),
        child: _BgAssetImage(fit: BoxFit.cover),
      );
    }

    final parent =
        (widget.stackKey.currentContext?.findRenderObject() as RenderBox?)
            ?.size;
    final parentW = parent?.width ?? pitch.width;
    final parentH = parent?.height ?? pitch.height;

    final imageW = pitch.width / region.width * scale;
    final imageH = pitch.height / region.height * scale;
    final left = pitch.left - region.left * imageW + nudge.dx * parentW;
    final top = pitch.top - region.top * imageH + nudge.dy * parentH;

    return ColoredBox(
      color: const Color(0xFF166534),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: left,
            top: top,
            width: imageW,
            height: imageH,
            child: const _BgAssetImage(fit: BoxFit.fill),
          ),
          if (TeamOrgBgConfig.debugShowPitchRegion)
            Positioned.fromRect(
              rect: pitch,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.redAccent, width: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BgAssetImage extends StatelessWidget {
  const _BgAssetImage({this.fit = BoxFit.cover});

  final BoxFit fit;

  static const _path = 'assets/images/team_organization_bg.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _path,
      fit: fit,
      alignment: Alignment.topLeft,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stack) {
        debugPrint('팀조직 배경 로드 실패: $error');
        return Container(
          color: const Color(0xFF334155),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(12),
          child: const Text(
            '배경 이미지를 불러오지 못했습니다.\n'
            'assets/images/team_organization_bg.png\n'
            '전체 재시작(q 후 ./run_local.sh) 해주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Pitch
// ---------------------------------------------------------------------------

class _StarterPitchPanel extends StatelessWidget {
  const _StarterPitchPanel({
    super.key,
    required this.formationName,
    this.layoutOutfield,
    required this.squad,
    required this.teamPower,
    required this.hoveredPlayerId,
    this.hoveredPositionFit,
    required this.rolesFor,
    required this.slotKeyFor,
    required this.draggingPlayerId,
    required this.dragActive,
    required this.hiddenPlayerIds,
    required this.moveDurationFor,
    required this.onHoverPlayer,
    required this.onHoverExitPlayer,
    required this.onInspectPlayer,
    required this.onTouchPressPlayer,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
    this.transparentField = false,
    this.hideDrawnLines = false,
  });

  final String formationName;
  final List<OutfieldLayoutPoint>? layoutOutfield;
  final List<ClubPlayer> squad;
  final int teamPower;
  final String? hoveredPlayerId;
  final Map<int, int>? hoveredPositionFit;
  final List<String> Function(String playerId) rolesFor;
  final GlobalKey Function(int positionIndex) slotKeyFor;
  final String? draggingPlayerId;
  final bool dragActive;
  final Set<String> hiddenPlayerIds;
  final Duration Function(String playerId) moveDurationFor;
  final ValueChanged<String?> onHoverPlayer;
  final ValueChanged<String> onHoverExitPlayer;
  final ValueChanged<String> onInspectPlayer;
  final ValueChanged<String> onTouchPressPlayer;
  final ValueChanged<_PlayerDragSession> onDragStart;
  final ValueChanged<Offset> onDragUpdate;
  final ValueChanged<Offset> onDragEnd;
  final VoidCallback onDragCancel;
  final bool transparentField;
  final bool hideDrawnLines;

  @override
  Widget build(BuildContext context) {
    final bySlot = <int, ClubPlayer>{
      for (final cp in squad)
        if (cp.isStarter) cp.positionIndex: cp,
    };

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black26),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final full = Size(constraints.maxWidth, constraints.maxHeight);
          // 적정포지션(시너지) 패널과 동일한 zoneRects 좌표계 사용
          final rawDots = FormationLayoutGrid.allDotOffsets(
            formationName: formationName,
            size: full,
            layoutOutfield: layoutOutfield,
          );
          // 레이아웃 앵커보다 아이콘을 위로 (카드 무게중심 보정)
          const iconYNudge = -5.0;
          final dots = [
            for (final d in rawDots) Offset(d.dx, d.dy + iconYNudge),
          ];
          return Stack(
            children: [
              if (!hideDrawnLines)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TeamPitchPainter(
                      drawFill: !transparentField,
                    ),
                  ),
                ),
              // 필드 배경 위 · 선수 아래 — 경기장 라인
              const Positioned(
                left: 1,
                top: 1,
                right: 1,
                bottom: 1,
                child: _PitchLineOverlay(),
              ),
              // 라인 위 · 선수 아래 — 시너지 주황 패널
              if (hoveredPositionFit != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: _SynergyZoneOverlay(
                      positionFit: hoveredPositionFit!,
                    ),
                  ),
                ),
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '전력: $teamPower',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              for (var i = 0; i < dots.length; i++) ...[
                // 드롭 판정용 고정 슬롯 (포지션 인덱스 1..11)
                Positioned(
                  left: dots[i].dx - 83 / 2,
                  top: dots[i].dy - 101 / 2,
                  width: 83,
                  height: 101,
                  child: KeyedSubtree(
                    key: slotKeyFor(i + 1),
                    child: const SizedBox.expand(),
                  ),
                ),
                if (bySlot[i + 1] != null)
                  _AnimatedPitchSlot(
                    key: ValueKey('pitch-${bySlot[i + 1]!.playerId}'),
                    offset: dots[i],
                    duration: moveDurationFor(bySlot[i + 1]!.playerId),
                    child: Opacity(
                      opacity: hiddenPlayerIds.contains(bySlot[i + 1]!.playerId)
                          ? 0
                          : 1,
                      child: _DraggablePlayerSlot(
                        clubPlayer: bySlot[i + 1]!,
                        selected: !dragActive &&
                            hoveredPlayerId == bySlot[i + 1]!.playerId,
                        roles: rolesFor(bySlot[i + 1]!.playerId),
                        dragging:
                            draggingPlayerId == bySlot[i + 1]!.playerId,
                        onHoverPlayer: onHoverPlayer,
                        onHoverExitPlayer: onHoverExitPlayer,
                        onInspectPlayer: onInspectPlayer,
                        onTouchPressPlayer: onTouchPressPlayer,
                        onDragStart: onDragStart,
                        onDragUpdate: onDragUpdate,
                        onDragEnd: onDragEnd,
                        onDragCancel: onDragCancel,
                        cardWidth: 83,
                        avatarRadius: 26,
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// 선택 선수의 position_fit 1~7 주황 투명도 표시 (1=0%·미표시 … 6~7=80%)
class _SynergyZoneOverlay extends StatelessWidget {
  const _SynergyZoneOverlay({required this.positionFit});

  final Map<int, int> positionFit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final rects = FieldZoneLayout.zoneRects(
          size,
          padding: FieldZoneLayout.zonePadding,
        );
        return Stack(
          children: [
            for (final entry in rects.entries)
              if (FieldZoneLayout.synergyColor(positionFit[entry.key] ?? 0) !=
                  null)
                Positioned(
                  left: entry.value.left,
                  top: entry.value.top,
                  width: entry.value.width,
                  height: entry.value.height,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: FieldZoneLayout.synergyColor(
                        positionFit[entry.key] ?? 0,
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

/// 흰 라인 + 투명 배경 PNG — 필드 위에 반투명으로 표시
class _PitchLineOverlay extends StatelessWidget {
  const _PitchLineOverlay();

  static const _path = 'assets/images/team_organization_line.png';

  /// 라인 전체 투명도 (0~1)
  static const double _opacity = 0.42;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: _opacity,
        child: Image.asset(
          _path,
          fit: BoxFit.fill,
          width: double.infinity,
          height: double.infinity,
          filterQuality: FilterQuality.medium,
          isAntiAlias: true,
          errorBuilder: (context, error, stack) {
            debugPrint('경기장 라인 로드 실패: $error');
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _AnimatedPitchSlot extends StatelessWidget {
  const _AnimatedPitchSlot({
    super.key,
    required this.offset,
    required this.duration,
    required this.child,
  });

  final Offset offset;
  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const cardW = 83.0;
    const cardH = 101.0;
    return AnimatedPositioned(
      duration: duration,
      curve: Curves.easeInOut,
      left: offset.dx - cardW / 2,
      top: offset.dy - cardH / 2,
      width: cardW,
      height: cardH,
      child: child,
    );
  }
}

class _TeamPitchPainter extends CustomPainter {
  _TeamPitchPainter({this.drawFill = true});

  final bool drawFill;

  @override
  void paint(Canvas canvas, Size size) {
    final fieldRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(8),
    );
    if (drawFill) {
      canvas.drawRRect(fieldRect, Paint()..color = const Color(0xFF166534));
    }

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final inset = size.width * 0.04;
    canvas.drawRect(
      Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2),
      line,
    );

    // halfway
    canvas.drawLine(
      Offset(inset, size.height / 2),
      Offset(size.width - inset, size.height / 2),
      line,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.12,
      line,
    );

    final boxW = size.width * 0.48;
    final boxH = size.height * 0.14;
    final boxCenterY = size.height * FormationPitchLayout.boxCenterYRatio;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, boxCenterY),
        width: boxW,
        height: boxH,
      ),
      line,
    );
    // attack box (top)
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * (1 - FormationPitchLayout.boxCenterYRatio)),
        width: boxW,
        height: boxH,
      ),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant _TeamPitchPainter oldDelegate) {
    return oldDelegate.drawFill != drawFill;
  }
}

// ---------------------------------------------------------------------------
// Bench
// ---------------------------------------------------------------------------

class _BenchZone extends StatelessWidget {
  const _BenchZone({
    super.key,
    required this.squad,
    required this.hoveredPlayerId,
    required this.rolesFor,
    required this.slotKeyFor,
    required this.draggingPlayerId,
    required this.dragActive,
    required this.hiddenPlayerIds,
    required this.moveDurationFor,
    required this.onHoverPlayer,
    required this.onHoverExitPlayer,
    required this.onInspectPlayer,
    required this.onTouchPressPlayer,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
    this.transparent = false,
  });

  final List<ClubPlayer> squad;
  final String? hoveredPlayerId;
  final List<String> Function(String playerId) rolesFor;
  final GlobalKey Function(int positionIndex) slotKeyFor;
  final String? draggingPlayerId;
  final bool dragActive;
  final Set<String> hiddenPlayerIds;
  final Duration Function(String playerId) moveDurationFor;
  final ValueChanged<String?> onHoverPlayer;
  final ValueChanged<String> onHoverExitPlayer;
  final ValueChanged<String> onInspectPlayer;
  final ValueChanged<String> onTouchPressPlayer;
  final ValueChanged<_PlayerDragSession> onDragStart;
  final ValueChanged<Offset> onDragUpdate;
  final ValueChanged<Offset> onDragEnd;
  final VoidCallback onDragCancel;
  final bool transparent;

  @override
  Widget build(BuildContext context) {
    final byIndex = <int, ClubPlayer>{
      for (final cp in squad)
        if (cp.isBench) cp.positionIndex: cp,
    };

    // 세로 두 열: 좌 12~16, 우 17~21
    Widget slot(int index) {
      final cp = byIndex[index];
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: KeyedSubtree(
            key: slotKeyFor(index),
            child: cp == null
                ? const SizedBox.expand()
                : Opacity(
                    opacity: hiddenPlayerIds.contains(cp.playerId) ? 0 : 1,
                    child: _DraggablePlayerSlot(
                      key: ValueKey('bench-${cp.playerId}'),
                      clubPlayer: cp,
                      selected:
                          !dragActive && hoveredPlayerId == cp.playerId,
                      roles: rolesFor(cp.playerId),
                      dragging: draggingPlayerId == cp.playerId,
                      onHoverPlayer: onHoverPlayer,
                      onHoverExitPlayer: onHoverExitPlayer,
                      onInspectPlayer: onInspectPlayer,
                      onTouchPressPlayer: onTouchPressPlayer,
                      onDragStart: onDragStart,
                      onDragUpdate: onDragUpdate,
                      onDragEnd: onDragEnd,
                      onDragCancel: onDragCancel,
                      cardWidth: null,
                      avatarRadius: 26,
                    ),
                  ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: transparent ? 0.28 : 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black45),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '후보',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      for (var i = 12; i <= 16; i++) slot(i),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      for (var i = 17; i <= 21; i++) slot(i),
                    ],
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
// Draggable slot
// ---------------------------------------------------------------------------

class _SwapFlight {
  _SwapFlight({
    required this.playerId,
    required this.player,
    required this.roles,
    required this.avatarRadius,
    required this.cardSize,
    required this.startTopLeft,
    required this.endTopLeft,
  }) : topLeft = startTopLeft;

  final String playerId;
  final Player player;
  final List<String> roles;
  final double avatarRadius;
  final Size cardSize;
  final Offset startTopLeft;
  final Offset endTopLeft;
  Offset topLeft;
}

class _PlayerDragSession {
  _PlayerDragSession({
    required this.playerId,
    required this.fromIndex,
    required this.player,
    required this.roles,
    required this.avatarRadius,
    required this.cardSize,
    required this.originTopLeft,
    required this.pointerOffsetInCard,
    required this.feedbackTopLeft,
  });

  final String playerId;
  final int fromIndex;
  final Player player;
  final List<String> roles;
  final double avatarRadius;
  final Size cardSize;
  final Offset originTopLeft;
  final Offset pointerOffsetInCard;
  Offset feedbackTopLeft;
  bool snappingBack = false;
}

class _DraggablePlayerSlot extends StatefulWidget {
  const _DraggablePlayerSlot({
    super.key,
    required this.clubPlayer,
    required this.selected,
    required this.roles,
    required this.dragging,
    required this.onHoverPlayer,
    required this.onHoverExitPlayer,
    required this.onInspectPlayer,
    required this.onTouchPressPlayer,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
    required this.avatarRadius,
    this.cardWidth,
  });

  final ClubPlayer clubPlayer;
  final bool selected;
  final List<String> roles;
  final bool dragging;
  final ValueChanged<String?> onHoverPlayer;
  final ValueChanged<String> onHoverExitPlayer;
  final ValueChanged<String> onInspectPlayer;
  final ValueChanged<String> onTouchPressPlayer;
  final ValueChanged<_PlayerDragSession> onDragStart;
  final ValueChanged<Offset> onDragUpdate;
  final ValueChanged<Offset> onDragEnd;
  final VoidCallback onDragCancel;
  final double avatarRadius;
  final double? cardWidth;

  @override
  State<_DraggablePlayerSlot> createState() => _DraggablePlayerSlotState();
}

class _DraggablePlayerSlotState extends State<_DraggablePlayerSlot> {
  bool _dragging = false;
  Offset? _lastGlobal;

  void _beginDrag(Offset global) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final origin = box.localToGlobal(Offset.zero);
    final size = box.size;
    _dragging = true;
    _lastGlobal = global;
    widget.onDragStart(
      _PlayerDragSession(
        playerId: widget.clubPlayer.playerId,
        fromIndex: widget.clubPlayer.positionIndex,
        player: widget.clubPlayer.player,
        roles: widget.roles,
        avatarRadius: widget.avatarRadius,
        cardSize: Size(widget.cardWidth ?? size.width, size.height),
        originTopLeft: origin,
        pointerOffsetInCard: global - origin,
        feedbackTopLeft: origin,
      ),
    );
    widget.onDragUpdate(global);
  }

  @override
  Widget build(BuildContext context) {
    final playerId = widget.clubPlayer.playerId;
    return MouseRegion(
      onEnter: (_) => widget.onHoverPlayer(playerId),
      onExit: (_) => widget.onHoverExitPlayer(playerId),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          if (event.kind == PointerDeviceKind.touch ||
              event.kind == PointerDeviceKind.stylus) {
            widget.onTouchPressPlayer(playerId);
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onInspectPlayer(playerId),
          onPanStart: (details) => _beginDrag(details.globalPosition),
          onPanUpdate: (details) {
            if (_dragging) {
              _lastGlobal = details.globalPosition;
              widget.onDragUpdate(details.globalPosition);
            }
          },
          onPanEnd: (details) {
            if (_dragging) {
              widget.onDragEnd(_lastGlobal ?? details.globalPosition);
              _dragging = false;
              _lastGlobal = null;
            }
          },
          onPanCancel: () {
            if (_dragging) {
              widget.onDragCancel();
              _dragging = false;
              _lastGlobal = null;
            }
          },
          child: _PlayerCard(
            player: widget.clubPlayer.player,
            roles: widget.roles,
            selected: widget.selected,
            avatarRadius: widget.avatarRadius,
            width: widget.cardWidth,
          ),
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.player,
    required this.roles,
    required this.selected,
    required this.avatarRadius,
    this.width,
    this.showMeta = true,
  });

  final Player player;
  final List<String> roles;
  final bool selected;
  final double avatarRadius;
  final double? width;
  final bool showMeta;

  Color get _posColor {
    return switch (player.position) {
      PlayerPosition.fw => const Color(0xFFEA580C),
      PlayerPosition.mf => const Color(0xFF16A34A),
      PlayerPosition.df => const Color(0xFF2563EB),
      PlayerPosition.gk => const Color(0xFF7C3AED),
    };
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: selected
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber, width: 2),
                  )
                : null,
            child: PlayerAvatar(
              name: player.name,
              portraitUrl: PlayerPortrait.expectedUrl(player),
              radius: avatarRadius,
              clipPortrait: false,
              // 높이 일괄 통일. 가로는 비율만 따름.
              portraitScale: 1.3,
            ),
          ),
          if (showMeta) ...[
          const SizedBox(height: 4),
          Transform.translate(
            offset: const Offset(0, -4),
            child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                // 선발(고정 폭)만 이름 테두리 가로 4px 축소
                padding: EdgeInsets.symmetric(horizontal: width != null ? 2 : 0),
                child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.70),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.90),
                    width: 1,
                  ),
                ),
                child: Text(
                  player.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ),
              Positioned(
                left: -2,
                top: -9,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: _posColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    player.position.code.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ),
              ),
              // 이름 테두리 오른쪽 상단(바깥)에서 위로 쌓임
              if (roles.isNotEmpty)
                Positioned(
                  right: -2,
                  top: 0,
                  child: FractionalTranslation(
                    translation: const Offset(0, -1),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      verticalDirection: VerticalDirection.up,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < roles.length; i++) ...[
                          if (i > 0) const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 3,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: skillRoleColor(roles[i]),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              roles[i],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
          ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats + roles
// ---------------------------------------------------------------------------

class _PlayerStatsPanel extends StatelessWidget {
  const _PlayerStatsPanel({
    required this.player,
    required this.matchStats,
    required this.styleLabels,
    required this.flagUrl,
    required this.rolesEnabled,
    required this.pkSelected,
    required this.fkSelected,
    required this.ckSelected,
    required this.capSelected,
    required this.onAssignRole,
  });

  static const _portraitW = 100.0;
  static const _portraitH = 130.0;
  /// 프레임(100×130)은 유지하고, 그 안 이미지만 기존(1.25) 대비 30% 축소.
  static const _portraitDisplayScale = 0.875; // 1.25 * 0.7
  static const _white = Colors.white;

  final Player player;
  final PlayerMatchStats matchStats;
  final List<String> styleLabels;
  final String? flagUrl;
  final bool rolesEnabled;
  final bool pkSelected;
  final bool fkSelected;
  final bool ckSelected;
  final bool capSelected;
  final ValueChanged<String> onAssignRole;

  @override
  Widget build(BuildContext context) {
    final age = player.ageStage?.trim();
    final height = player.height;
    final weight = player.weight;
    final metaParts = <String>[
      if (age != null && age.isNotEmpty) '${age.replaceAll(RegExp(r'세$'), '')}세',
      if (height != null) '${height}cm',
      if (weight != null) '${weight}kg',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          player.name,
          style: const TextStyle(
            color: _white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: _portraitW,
                      height: _portraitH,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: ColoredBox(
                          color: Colors.black26,
                          child: Center(
                            child: Image.network(
                              PlayerPortrait.expectedUrl(player),
                              // 폭 맞춤(fitWidth) 금지 — 높이만 통일, 가로는 원본 비율.
                              height: _portraitH * _portraitDisplayScale,
                              alignment: Alignment.topCenter,
                              filterQuality: FilterQuality.medium,
                              errorBuilder: (_, _, _) => SizedBox(
                                width: _portraitW * _portraitDisplayScale,
                                height: _portraitH * _portraitDisplayScale,
                                child: const Center(
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white38,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProfileHeaderBadges(
                            positionLabel: playerPositionBadgeLabel(player),
                            flagUrl: flagUrl,
                            rank: player.rank,
                          ),
                          if (metaParts.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              metaParts.join(' / '),
                              style: const TextStyle(
                                color: _white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (styleLabels.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            PlayerStyleChips(
                              styleLabels: styleLabels,
                              dense: true,
                              panelStyle: true,
                              maxLines: 2,
                            ),
                          ],
                          const SizedBox(height: 6),
                          _MatchStatsTable(stats: matchStats),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '능력치',
                  style: TextStyle(color: _white, fontWeight: FontWeight.bold),
                ),
                GameStatBar(
                  label: '스피드',
                  value: player.speed,
                  color: Colors.lightBlue,
                  compact: true,
                  textColor: _white,
                ),
                GameStatBar(
                  label: '파워',
                  value: player.power,
                  color: Colors.redAccent,
                  compact: true,
                  textColor: _white,
                ),
                GameStatBar(
                  label: '기술',
                  value: player.technique,
                  color: Colors.amber,
                  compact: true,
                  textColor: _white,
                ),
                GameStatBar(
                  label: '슈팅',
                  value: player.shooting,
                  color: Colors.orange,
                  compact: true,
                  textColor: _white,
                ),
                GameStatBar(
                  label: '패스',
                  value: player.passing,
                  color: Colors.teal,
                  compact: true,
                  textColor: _white,
                ),
                GameStatBar(
                  label: '스태미나',
                  value: player.stamina,
                  color: Colors.green,
                  compact: true,
                  textColor: _white,
                ),
                const SizedBox(height: 6),
                const Text(
                  '스킬능력',
                  style: TextStyle(color: _white, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Expanded(
                      child: GameStatBar(
                        label: '패널티킥',
                        value: player.pkAbility,
                        color: Colors.orange,
                        compact: true,
                        textColor: _white,
                        labelWidth: 52,
                      ),
                    ),
                    const SizedBox(width: 25),
                    Expanded(
                      child: GameStatBar(
                        label: '프리킥',
                        value: player.fkAbility,
                        color: Colors.orange,
                        compact: true,
                        textColor: _white,
                        labelWidth: 42,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: GameStatBar(
                        label: '코너킥',
                        value: player.ckAbility,
                        color: Colors.orange,
                        compact: true,
                        textColor: _white,
                        labelWidth: 52,
                      ),
                    ),
                    const SizedBox(width: 25),
                    Expanded(
                      child: GameStatBar(
                        label: '팀주장',
                        value: player.leadership,
                        color: Colors.orange,
                        compact: true,
                        textColor: _white,
                        labelWidth: 42,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '역할 설정',
          style: TextStyle(color: _white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _RoleChip(
              label: 'PK',
              selected: pkSelected,
              enabled: rolesEnabled,
              selectedColor: skillRoleColor('PK'),
              onTap: rolesEnabled && !pkSelected
                  ? () => onAssignRole('pk')
                  : null,
            ),
            _RoleChip(
              label: 'FK',
              selected: fkSelected,
              enabled: rolesEnabled,
              selectedColor: skillRoleColor('FK'),
              onTap: rolesEnabled && !fkSelected
                  ? () => onAssignRole('fk')
                  : null,
            ),
            _RoleChip(
              label: 'CK',
              selected: ckSelected,
              enabled: rolesEnabled,
              selectedColor: skillRoleColor('CK'),
              onTap: rolesEnabled && !ckSelected
                  ? () => onAssignRole('ck')
                  : null,
            ),
            _RoleChip(
              label: 'Cap.',
              selected: capSelected,
              enabled: rolesEnabled,
              selectedColor: skillRoleColor('Cap.'),
              onTap: rolesEnabled && !capSelected
                  ? () => onAssignRole('cap')
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _MatchStatsTable extends StatelessWidget {
  const _MatchStatsTable({required this.stats});

  final PlayerMatchStats stats;

  @override
  Widget build(BuildContext context) {
    String r(double v) => v == v.roundToDouble() ? '${v.toInt()}' : v.toStringAsFixed(1);

    Widget cell(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          children: [
            SizedBox(
              width: 42,
              child: Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                cell('경기', '${stats.matches}'),
                cell('득점', '${stats.goals}'),
                cell('어시스트', '${stats.assists}'),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                cell('옐로우', '${stats.yellowCards}'),
                cell('레드', '${stats.redCards}'),
                cell('평점', r(stats.rating)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.selectedColor,
    this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final Color selectedColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    if (!enabled) {
      bg = const Color(0xFF4B5563);
    } else if (selected) {
      bg = selectedColor;
    } else {
      bg = const Color(0xFF374151);
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: enabled && selected ? Colors.amber : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: enabled ? Colors.white : Colors.white54,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
