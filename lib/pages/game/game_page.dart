import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/coach.dart';
import '../../models/formation.dart';
import '../../models/game_club.dart';
import '../../models/player.dart';
import '../../models/player_position.dart';
import '../../services/app_services.dart';
import '../../utils/coach_portrait.dart';
import 'game_user_settings_page.dart';
import '../../widgets/formation_pitch_diagram.dart';
import '../../widgets/common_widgets.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key, required this.services});

  final AppServices services;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  bool _bootstrapping = true;
  bool _loadingClub = false;
  bool _signedIn = false;
  bool _signingIn = false;
  bool _showUserSettings = false;
  bool _settingsProcessing = false;
  String? _error;

  GameClub? _club;

  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = widget.services.authService.onAuthStateChange.listen(
      _onAuthStateChanged,
    );
    _bootstrapSession();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _onAuthStateChanged(AuthState state) {
    if (!mounted) {
      return;
    }
    switch (state.event) {
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.tokenRefreshed:
        if (state.session != null) {
          _loadUserClub();
        }
      case AuthChangeEvent.signedOut:
        setState(() {
          _signedIn = false;
          _club = null;
          _error = null;
          _bootstrapping = false;
          _loadingClub = false;
          _signingIn = false;
          _showUserSettings = false;
          _settingsProcessing = false;
        });
      default:
        break;
    }
  }

  Future<void> _bootstrapSession() async {
    if (widget.services.authService.currentSession != null) {
      await _loadUserClub();
      return;
    }
    if (mounted) {
      setState(() => _bootstrapping = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    await _startOAuthSignIn(widget.services.authService.signInWithGoogle);
  }

  Future<void> _signInWithNaver() async {
    await _startOAuthSignIn(widget.services.authService.signInWithNaver);
  }

  Future<void> _startOAuthSignIn(Future<void> Function() signIn) async {
    setState(() {
      _signingIn = true;
      _error = null;
    });
    try {
      await signIn();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _signingIn = false;
      });
    }
  }

  Future<void> _loadUserClub() async {
    final user = widget.services.authService.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _bootstrapping = false;
          _loadingClub = false;
          _signedIn = false;
        });
      }
      return;
    }

    setState(() {
      _bootstrapping = false;
      _signedIn = true;
      _loadingClub = true;
      _error = null;
      _signingIn = false;
    });

    try {
      final club = await widget.services.gameClubService.fetchUserClub(
        userId: user.id,
        playerService: widget.services.playerService,
        coachService: widget.services.coachService,
        formationService: widget.services.formationService,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _club = club;
        _loadingClub = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loadingClub = false;
      });
    }
  }

  Future<void> _createClub(GameClub club) async {
    final user = widget.services.authService.currentUser;
    if (user == null) {
      throw StateError('로그인이 필요합니다.');
    }
    final saved = await widget.services.gameClubService.createUserClub(
      club: club,
      userId: user.id,
    );
    setState(() => _club = saved);
  }

  Future<void> _signOut() async {
    await widget.services.authService.signOut();
  }

  Future<void> _signOutFromSettings() async {
    setState(() => _settingsProcessing = true);
    try {
      await widget.services.authService.signOut();
    } finally {
      if (mounted) {
        setState(() {
          _settingsProcessing = false;
          _showUserSettings = false;
        });
      }
    }
  }

  Future<void> _withdrawAccount() async {
    final user = widget.services.authService.currentUser;
    if (user == null) {
      return;
    }
    setState(() => _settingsProcessing = true);
    try {
      await widget.services.gameClubService.deleteUserClubData(userId: user.id);
      await widget.services.authService.signOut();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _settingsProcessing = false;
      });
      return;
    }
    if (mounted) {
      setState(() {
        _settingsProcessing = false;
        _showUserSettings = false;
        _club = null;
      });
    }
  }

  String _currentUserLabel() {
    final user = widget.services.authService.currentUser;
    if (user == null) {
      return '';
    }
    return user.email ?? user.userMetadata?['name']?.toString() ?? user.id;
  }

  @override
  Widget build(BuildContext context) {
    if (_bootstrapping || (_signedIn && _loadingClub && !_showUserSettings)) {
      return const Scaffold(
        body: LoadingView(message: '구단 정보 불러오는 중...'),
      );
    }
    if (_signedIn && _showUserSettings) {
      return GameUserSettingsPage(
        userLabel: _currentUserLabel(),
        processing: _settingsProcessing,
        onBack: () => setState(() => _showUserSettings = false),
        onLogout: _signOutFromSettings,
        onWithdraw: _withdrawAccount,
      );
    }
    if (!_signedIn) {
      return _GameLoginView(
        signingIn: _signingIn,
        error: _error,
        onGoogleLogin: _signInWithGoogle,
        onNaverLogin: _signInWithNaver,
      );
    }
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _loadUserClub);
    }
    if (_club == null) {
      return _GameSetupView(
        services: widget.services,
        onCreateClub: _createClub,
        onOpenUserSettings: () => setState(() => _showUserSettings = true),
      );
    }

    return _GameHomeView(
      club: _club!,
      onReset: () => setState(() => _club = null),
      onLogout: _signOut,
      onOpenUserSettings: () => setState(() => _showUserSettings = true),
    );
  }
}

class _GameLoginView extends StatelessWidget {
  const _GameLoginView({
    required this.onGoogleLogin,
    required this.onNaverLogin,
    this.signingIn = false,
    this.error,
  });

  final VoidCallback onGoogleLogin;
  final VoidCallback onNaverLogin;
  final bool signingIn;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F5132), Color(0xFF052E16)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.sports_soccer,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Again26',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Google 또는 네이버 계정으로 로그인하고 구단을 이어가세요.',
                      textAlign: TextAlign.center,
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: signingIn ? null : onGoogleLogin,
                      icon: signingIn
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.g_mobiledata, size: 28),
                      label: Text(signingIn ? '로그인 페이지로 이동 중...' : 'Google로 로그인'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: signingIn ? null : onNaverLogin,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF03C75A),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('네이버로 로그인'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('메인으로 돌아가기'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameSetupView extends StatefulWidget {
  const _GameSetupView({
    required this.services,
    required this.onCreateClub,
    required this.onOpenUserSettings,
  });

  final AppServices services;
  final Future<void> Function(GameClub club) onCreateClub;
  final VoidCallback onOpenUserSettings;

  @override
  State<_GameSetupView> createState() => _GameSetupViewState();
}

class _GameSetupViewState extends State<_GameSetupView> {
  final _clubNameController = TextEditingController(text: 'FCjickson');
  Formation? _selectedFormation;
  Coach? _selectedCoach;
  bool _saving = false;
  bool _loadingOptions = true;
  bool _loadingPlayers = false;
  String? _optionsError;

  List<Formation> _formations = [];
  List<Coach> _coaches = [];

  static const _initialFormationIds = [
    'fm_4231_press',
    'fm_433_wing',
    'fm_442_balance',
    'fm_352_engine',
  ];

  @override
  void initState() {
    super.initState();
    _loadSetupOptions();
  }

  Future<void> _loadSetupOptions() async {
    setState(() {
      _loadingOptions = true;
      _optionsError = null;
    });
    try {
      final formationResults = await Future.wait(
        _initialFormationIds.map(widget.services.formationService.fetchById),
      );
      if (!mounted) {
        return;
      }
      final formations = [
        for (final formation in formationResults)
          if (formation != null) formation,
      ];
      final firstFormation = formations.isNotEmpty ? formations.first : null;
      final coaches = firstFormation == null
          ? const <Coach>[]
          : await widget.services.coachService
              .fetchGoodFitForFormation(firstFormation.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _formations = formations;
        _coaches = coaches;
        _loadingOptions = false;
        _selectedFormation = firstFormation;
        _selectedCoach = coaches.isNotEmpty ? coaches.first : null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _optionsError = error.toString();
        _loadingOptions = false;
      });
    }
  }

  Future<void> _loadCoachesForFormation(String formationId) async {
    try {
      final coaches =
          await widget.services.coachService.fetchGoodFitForFormation(
        formationId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _coaches = coaches;
        _selectedCoach = coaches.contains(_selectedCoach)
            ? _selectedCoach
            : coaches.isNotEmpty
            ? coaches.first
            : null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('감독 목록 불러오기 실패: $error')),
      );
    }
  }

  @override
  void dispose() {
    _clubNameController.dispose();
    super.dispose();
  }

  List<Formation> _initialFormations() {
    if (_formations.isNotEmpty) {
      return _formations;
    }
    return const [];
  }

  List<Coach> _availableCoaches() => _coaches;

  void _selectFormation(Formation formation) {
    setState(() => _selectedFormation = formation);
    _loadCoachesForFormation(formation.id);
  }

  Future<void> _startGame() async {
    final clubName = _clubNameController.text.trim();
    final formation = _selectedFormation;
    final coach = _selectedCoach;
    if (clubName.isEmpty || formation == null || coach == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('구단명, 포메이션, 감독을 모두 선택하세요.')));
      return;
    }

    setState(() => _loadingPlayers = true);
    List<Player> players;
    try {
      players = await widget.services.playerService.fetchByRank(1);
    } catch (error) {
      if (mounted) {
        setState(() => _loadingPlayers = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('선수 목록 불러오기 실패: $error')),
        );
      }
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => _loadingPlayers = false);

    final roster = _buildInitialRoster(players);
    if (roster.starters.length < 11 || roster.bench.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '1랭크 선수 풀이 부족합니다. 선발 ${roster.starters.length}/11, 후보 ${roster.bench.length}/10',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.onCreateClub(
        GameClub(
          clubName: clubName,
          formation: formation,
          coach: coach,
          starters: roster.starters,
          bench: roster.bench,
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('구단 저장 실패: $error')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  ({List<Player> starters, List<Player> bench}) _buildInitialRoster(
    List<Player> players,
  ) {
    final random = Random();
    final rankOne = players.where((player) => player.rank == 1).toList()
      ..shuffle(random);
    final gks = rankOne
        .where((player) => player.position == PlayerPosition.gk)
        .toList();
    final outfield = rankOne
        .where((player) => player.position != PlayerPosition.gk)
        .toList();
    if (gks.isEmpty) {
      return (starters: const <Player>[], bench: const <Player>[]);
    }

    final starters = <Player>[gks.first, ...outfield.take(10)];
    final usedIds = starters.map((player) => player.id).toSet();
    final bench = rankOne
        .where((player) => !usedIds.contains(player.id))
        .take(10)
        .toList();
    return (starters: starters, bench: bench);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingOptions) {
      return Scaffold(
        appBar: AppBar(title: const Text('구단 생성')),
        body: const LoadingView(message: '포메이션·감독 후보 불러오는 중...'),
      );
    }
    if (_optionsError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('구단 생성')),
        body: ErrorView(message: _optionsError!, onRetry: _loadSetupOptions),
      );
    }

    final initialFormations = _initialFormations();
    final availableCoaches = _availableCoaches();

    return Scaffold(
      appBar: AppBar(
        title: const Text('구단 생성'),
        actions: [
          TextButton(
            onPressed: widget.onOpenUserSettings,
            child: const Text('사용자 설정'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('새 구단 설정', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text(
                'Google 계정으로 로그인된 상태입니다. 구단을 만들면 계정에 저장됩니다.',
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _clubNameController,
                decoration: const InputDecoration(
                  labelText: '구단 이름',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '초기 포메이션 선택',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final formation in initialFormations)
                    ChoiceChip(
                      selected: formation.id == _selectedFormation?.id,
                      label: Text(formation.name),
                      onSelected: (_) => _selectFormation(formation),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text('감독 선택', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<Coach>(
                key: ValueKey(_selectedFormation?.id),
                initialValue: availableCoaches.contains(_selectedCoach)
                    ? _selectedCoach
                    : null,
                items: [
                  for (final coach in availableCoaches)
                    DropdownMenuItem(
                      value: coach,
                      child: Text(
                        '${coach.name} · ${coach.coachType} · 랭크 ${coach.effectiveRank}',
                      ),
                    ),
                ],
                onChanged: (coach) => setState(() => _selectedCoach = coach),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  helperText: _selectedFormation == null
                      ? '포메이션을 먼저 선택하세요.'
                      : '선택한 포메이션이 높은 적합인 감독을 우선 표시합니다.',
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '초기 편성: ${GameLeagueTier.second.label} 배정 · 주전 11명 · 후보 10명 · 1랭크 선수 랜덤 배치',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: (_saving || _loadingPlayers) ? null : _startGame,
                icon: _saving || _loadingPlayers
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.flag),
                label: Text(
                  _loadingPlayers
                      ? '1랭크 선수 불러오는 중...'
                      : _saving
                      ? '저장 중...'
                      : '구단 생성하고 시작',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameHomeView extends StatefulWidget {
  const _GameHomeView({
    required this.club,
    required this.onReset,
    required this.onLogout,
    required this.onOpenUserSettings,
  });

  final GameClub club;
  final VoidCallback onReset;
  final VoidCallback onLogout;
  final VoidCallback onOpenUserSettings;

  @override
  State<_GameHomeView> createState() => _GameHomeViewState();
}

class _GameHomeViewState extends State<_GameHomeView> {
  String _selectedMenu = '홈';
  String _selectedNavTab = '팀 조직';

  static const _viewportHorizontalPadding = 24.0;
  static const _gameShellMaxWidth = 980.0;
  static const _gameBoardMaxWidth = 860.0;

  Widget _buildMainContent(bool compact) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: 12,
      ),
      child: Column(
        children: [
          _DashboardMainArea(club: widget.club),
          const SizedBox(height: 12),
          _RosterPanel(
            title: '선발 11명',
            players: widget.club.starters,
          ),
          const SizedBox(height: 12),
          _AchievementPanel(club: widget.club),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4D7C0F), Color(0xFF166534)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final content = Column(
                children: [
                  _GameUtilityBar(
                    compact: compact,
                    onUserSettings: widget.onOpenUserSettings,
                  ),
                  _GameMainNavBar(
                    compact: compact,
                    selected: _selectedNavTab,
                    onSelected: (tab) => setState(() => _selectedNavTab = tab),
                  ),
                  _GameClubHeader(club: widget.club, compact: compact),
                  Expanded(child: _buildMainContent(compact)),
                ],
              );

              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _viewportHorizontalPadding,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _gameShellMaxWidth,
                    ),
                    child: compact
                        ? Column(
                            children: [
                              _GameSideMenu(
                                selected: _selectedMenu,
                                onSelected: (menu) =>
                                    setState(() => _selectedMenu = menu),
                                onReset: widget.onReset,
                                onLogout: widget.onLogout,
                                horizontal: true,
                              ),
                              Expanded(child: content),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _GameSideMenu(
                                selected: _selectedMenu,
                                onSelected: (menu) =>
                                    setState(() => _selectedMenu = menu),
                                onReset: widget.onReset,
                                onLogout: widget.onLogout,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: _gameBoardMaxWidth,
                                    ),
                                    child: content,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GameUtilityBar extends StatelessWidget {
  const _GameUtilityBar({
    required this.compact,
    required this.onUserSettings,
  });

  final bool compact;
  final VoidCallback onUserSettings;

  static const _links = [
    '사용자 설정',
    '도움말',
    '팀 검색',
    '포인트 통장',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(compact ? 8 : 0, 8, compact ? 8 : 0, 0),
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        border: Border.all(color: Colors.black26),
      ),
      child: Row(
        children: [
          if (!compact)
            Expanded(
              child: Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  for (final link in _links)
                    InkWell(
                      onTap: link == '사용자 설정' ? onUserSettings : null,
                      child: Text(
                        link,
                        style: TextStyle(
                          fontSize: 11,
                          color: link == '사용자 설정'
                              ? const Color(0xFF1D4ED8)
                              : Colors.grey.shade600,
                          decoration: link == '사용자 설정'
                              ? TextDecoration.underline
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                ],
              ),
            )
          else
            Expanded(
              child: InkWell(
                onTap: onUserSettings,
                child: const Text(
                  '사용자 설정',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D4ED8),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFACC15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.black45),
            ),
            child: const Text(
              'G 구입',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameMainNavBar extends StatelessWidget {
  const _GameMainNavBar({
    required this.compact,
    required this.selected,
    required this.onSelected,
  });

  final bool compact;
  final String selected;
  final ValueChanged<String> onSelected;

  static const _tabs = [
    ('아레나 리그', Icons.emoji_events_outlined),
    ('월드 투어', Icons.public),
    ('팀 조직', Icons.groups),
    ('상점', Icons.storefront),
    ('메뉴', Icons.menu),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: compact ? 8 : 0),
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
        ),
        border: Border.all(color: Colors.black45),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.black26),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sports_soccer, size: compact ? 18 : 22, color: const Color(0xFF1D4ED8)),
                if (!compact) ...[
                  const SizedBox(width: 6),
                  const Text(
                    'AGAIN26',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final tab in _tabs)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: _MainNavTab(
                        label: tab.$1,
                        icon: tab.$2,
                        selected: selected == tab.$1,
                        compact: compact,
                        onTap: () => onSelected(tab.$1),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MainNavTab extends StatelessWidget {
  const _MainNavTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF0F172A) : const Color(0xFF334155),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 12,
            vertical: compact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: selected ? Colors.white70 : Colors.black26,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: compact ? 16 : 18),
              const SizedBox(width: 4),
              Text(
                compact ? label.split(' ').first : label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameClubHeader extends StatelessWidget {
  const _GameClubHeader({required this.club, this.compact = false});

  final GameClub club;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(compact ? 8 : 0, 0, compact ? 8 : 0, 0),
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
        ),
        border: Border.all(color: Colors.black45),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 36 : 44,
            height: compact ? 36 : 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black26, width: 2),
            ),
            child: club.clubLogoUrl == null
                ? const Icon(Icons.shield, color: Color(0xFF0B67C2))
                : ClipOval(child: Image.network(club.clubLogoUrl!, fit: BoxFit.cover)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              club.clubName,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 18 : 24,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!compact) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  '엔트리 / 엔트리',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '현재 375 위',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.north_east, color: Color(0xFFFACC15), size: 16),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Row(
              children: [
                _NotificationIcon(icon: Icons.card_giftcard, count: 2),
                const SizedBox(width: 6),
                _NotificationIcon(icon: Icons.emoji_events, count: 1),
                const SizedBox(width: 6),
                const Icon(Icons.article_outlined, color: Colors.white, size: 22),
                const SizedBox(width: 6),
                const Icon(Icons.settings, color: Colors.white, size: 22),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _CurrencyChip(label: '3000 P', color: Color(0xFF22C55E)),
                SizedBox(height: 4),
                _CurrencyChip(label: '0 G', color: Color(0xFFEF4444)),
              ],
            ),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                club.leagueTier.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.icon, required this.count});

  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: Colors.white, size: 26),
        Positioned(
          right: -4,
          top: -4,
          child: Container(
            width: 16,
            height: 16,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  const _CurrencyChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardMainArea extends StatelessWidget {
  const _DashboardMainArea({required this.club});

  final GameClub club;

  // 경기일정(넓음) : 포메이션 : 감독 = 62 : 19 : 19
  static const _scheduleFlex = 62;
  static const _pitchFlex = 19;
  static const _coachFlex = 19;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final schedule = _SchedulePanel(club: club);
        final pitch = _PitchPanel(club: club);
        final coach = _CoachPanel(club: club);

        if (compact) {
          return Column(
            children: [
              schedule,
              const SizedBox(height: 8),
              pitch,
              const SizedBox(height: 8),
              coach,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: _scheduleFlex, child: schedule),
            const SizedBox(width: 6),
            Expanded(flex: _pitchFlex, child: pitch),
            const SizedBox(width: 6),
            Expanded(flex: _coachFlex, child: coach),
          ],
        );
      },
    );
  }
}

class _SchedulePanel extends StatelessWidget {
  const _SchedulePanel({required this.club});

  final GameClub club;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black45, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: const Color(0xFF1E3A8A),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '엔트리 / 엔트리',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '현재 375',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.north_east, color: Color(0xFFFACC15), size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.sports_soccer, size: 16, color: Colors.grey.shade700),
                    const SizedBox(width: 4),
                    const Text(
                      '최신 경기 결과',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${club.leagueTier.label} · 시즌 준비',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '⚽ 최근 일정이 여기에 표시됩니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade400),
                      bottom: BorderSide(color: Colors.grey.shade400),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('MON', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      Text('TUE', style: TextStyle(fontSize: 11)),
                      Text('WED', style: TextStyle(fontSize: 11)),
                      Text('THU', style: TextStyle(fontSize: 11)),
                      Text('FRI', style: TextStyle(fontSize: 11)),
                      Text('SAT', style: TextStyle(fontSize: 11)),
                      Text('SUN', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: const Color(0xFF005BAA),
            child: Text(
              '0 승 0 패 0 분 · ${club.leagueTier.label}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _PitchPanel extends StatelessWidget {
  const _PitchPanel({required this.club});

  final GameClub club;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pitchSize = (constraints.maxWidth - 24).clamp(90.0, 180.0);

        return _GamePanel(
          title: club.formation.name,
          child: Column(
            children: [
              Center(
                child: FormationPitchDiagram(
                  formationName: club.formation.name,
                  keySlots: club.formation.keyPositionSlots.toSet(),
                  size: pitchSize,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '선발 ${club.starters.length}명',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CoachPanel extends StatelessWidget {
  const _CoachPanel({required this.club});

  final GameClub club;

  @override
  Widget build(BuildContext context) {
    final coach = club.coach;
    const avatarRadius = 28.0;
    final maxLeadership = coach.leadershipCurve.isEmpty
        ? 0
        : coach.leadershipCurve.reduce(max);

    return _GamePanel(
      title: '감독',
      dark: true,
      child: Column(
        children: [
          ClipOval(
            child: Image.network(
              CoachPortrait.urlFor(coach.id),
              width: avatarRadius * 2,
              height: avatarRadius * 2,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => CircleAvatar(
                radius: avatarRadius,
                backgroundColor: Colors.white24,
                child: Text(
                  coach.name.isNotEmpty ? coach.name.characters.first : '?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: avatarRadius * 0.8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            coach.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            coach.coachType,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            '${coach.baseLeadership}/$maxLeadership',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            coach.abilityName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _RosterPanel extends StatelessWidget {
  const _RosterPanel({required this.title, required this.players});

  final String title;
  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    return _GamePanel(
      title: title,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final player in players)
            Chip(
              avatar: CircleAvatar(
                child: Text(player.position.code.toUpperCase()),
              ),
              label: Text(player.name),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

class _AchievementPanel extends StatelessWidget {
  const _AchievementPanel({required this.club});

  final GameClub club;

  @override
  Widget build(BuildContext context) {
    return _GamePanel(
      title: '성적',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _RecordItem(label: '통산 승무', value: '0승 0무 0패'),
              _RecordItem(label: '승률', value: '0.00%'),
              _RecordItem(label: '우승 횟수', value: '0회'),
              _RecordItem(label: '리그 재적기수', value: '1기'),
            ],
          ),
          const Divider(height: 24),
          _RosterPanel(title: '벤치 후보 10명', players: club.bench),
        ],
      ),
    );
  }
}

class _RecordItem extends StatelessWidget {
  const _RecordItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _GamePanel extends StatelessWidget {
  const _GamePanel({
    required this.title,
    required this.child,
    this.dark = false,
  });

  final String title;
  final Widget child;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF6B1D12) : Colors.white,
        border: Border.all(color: Colors.black45),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: dark ? const Color(0xFF3A0E08) : const Color(0xFF005BAA),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(12), child: child),
        ],
      ),
    );
  }
}

class _GameSideMenu extends StatelessWidget {
  const _GameSideMenu({
    required this.selected,
    required this.onSelected,
    required this.onReset,
    required this.onLogout,
    this.horizontal = false,
  });

  final String selected;
  final ValueChanged<String> onSelected;
  final VoidCallback onReset;
  final VoidCallback onLogout;
  final bool horizontal;

  static const _items = [
    ('홈', Icons.home),
    ('팀 조직', Icons.account_tree),
    ('스케줄', Icons.calendar_month),
    ('리그', Icons.emoji_events),
    ('컵전', Icons.workspace_premium),
    ('친선 경기', Icons.sports_soccer),
    ('팀 데이터', Icons.badge),
    ('팀 히스토리', Icons.flag),
    ('리그 히스토리', Icons.article),
  ];

  @override
  Widget build(BuildContext context) {
    final children = [
      for (final item in _items)
        _MenuTile(
          label: item.$1,
          icon: item.$2,
          selected: selected == item.$1,
          onTap: () => onSelected(item.$1),
          compact: horizontal,
        ),
      if (!horizontal) ...[
        const Divider(height: 1),
        TextButton(
          onPressed: onReset,
          child: const Text('구단 재설정', style: TextStyle(fontSize: 12)),
        ),
        TextButton(
          onPressed: onLogout,
          child: const Text('로그아웃', style: TextStyle(fontSize: 12)),
        ),
      ],
    ];

    return Container(
      width: horizontal ? double.infinity : 116,
      height: horizontal ? 104 : null,
      margin: horizontal
          ? const EdgeInsets.fromLTRB(8, 8, 8, 0)
          : const EdgeInsets.fromLTRB(12, 12, 0, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView(
        scrollDirection: horizontal ? Axis.horizontal : Axis.vertical,
        padding: EdgeInsets.zero,
        children: children,
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: compact ? 86 : null,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: compact ? 8 : 12,
            horizontal: compact ? 6 : 8,
          ),
          color: selected ? Colors.red.shade800 : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: compact ? 42 : 52,
                height: compact ? 42 : 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: selected
                        ? [Colors.red.shade300, Colors.red.shade900]
                        : [Colors.red.shade200, Colors.grey.shade700],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(blurRadius: 3, color: Colors.black26),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: compact ? 24 : 30),
              ),
              SizedBox(height: compact ? 4 : 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: compact ? 11 : 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
