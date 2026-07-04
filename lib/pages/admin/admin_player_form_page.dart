import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/player.dart';
import '../../models/player_growth.dart';
import '../../models/player_position.dart';
import '../../services/player_service.dart';
import '../../widgets/common_widgets.dart';

class AdminPlayerFormPage extends StatefulWidget {
  const AdminPlayerFormPage({
    super.key,
    required this.playerService,
    this.playerId,
  });

  final PlayerService playerService;
  final String? playerId;

  bool get isEditing => playerId != null;

  @override
  State<AdminPlayerFormPage> createState() => _AdminPlayerFormPageState();
}

class _AdminPlayerFormPageState extends State<AdminPlayerFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _fakeNameController = TextEditingController();
  final _rankController = TextEditingController();
  final _ageStageController = TextEditingController();
  final _peakAgeController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _portraitUrlController = TextEditingController();
  final _seedNamesController = TextEditingController();

  PlayerPosition _position = PlayerPosition.mf;
  Map<int, int> _positionFit = Player.defaultPositionFit();
  List<PlayerGrowth> _growthType = Player.defaultGrowthType();
  int _speed = 0;
  int _power = 0;
  int _technique = 0;
  int _pkAbility = 0;
  int _fkAbility = 0;
  int _ckAbility = 0;
  int _leadership = 0;
  int _intelligenceSense = 5;
  int _individualOrganization = 5;

  bool _loading = false;
  bool _initialLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadPlayer();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fakeNameController.dispose();
    _rankController.dispose();
    _ageStageController.dispose();
    _peakAgeController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _nationalityController.dispose();
    _portraitUrlController.dispose();
    _seedNamesController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayer() async {
    setState(() {
      _initialLoading = true;
      _error = null;
    });

    try {
      final player = await widget.playerService.fetchById(widget.playerId!);
      if (!mounted) {
        return;
      }

      if (player == null) {
        setState(() {
          _error = '선수를 찾을 수 없습니다.';
          _initialLoading = false;
        });
        return;
      }

      _applyPlayer(player);
      setState(() => _initialLoading = false);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _initialLoading = false;
      });
    }
  }

  void _applyPlayer(Player player) {
    _nameController.text = player.name;
    _fakeNameController.text = player.fakeName ?? '';
    _rankController.text = player.rank?.toString() ?? '';
    _ageStageController.text = player.ageStage ?? '';
    _peakAgeController.text = player.peakAge?.toString() ?? '';
    _heightController.text = player.height?.toString() ?? '';
    _weightController.text = player.weight?.toString() ?? '';
    _nationalityController.text = player.nationality ?? '';
    _portraitUrlController.text = player.portraitUrl ?? '';
    _seedNamesController.text = player.seedNames.join('; ');
    _position = player.position;
    _positionFit = Map<int, int>.from(player.positionFit);
    _growthType = List<PlayerGrowth>.from(player.growthType);
    _speed = player.speed;
    _power = player.power;
    _technique = player.technique;
    _pkAbility = player.pkAbility;
    _fkAbility = player.fkAbility;
    _ckAbility = player.ckAbility;
    _leadership = player.leadership;
    _intelligenceSense = player.intelligenceSense;
    _individualOrganization = player.individualOrganization;
  }

  Player _buildPlayer({String? id}) {
    return Player(
      id: id ?? '',
      name: _nameController.text.trim(),
      fakeName: _fakeNameController.text.trim().isEmpty
          ? null
          : _fakeNameController.text.trim(),
      position: _position,
      positionFit: _positionFit,
      rank: int.tryParse(_rankController.text.trim()),
      ageStage: _ageStageController.text.trim().isEmpty
          ? null
          : _ageStageController.text.trim(),
      peakAge: int.tryParse(_peakAgeController.text.trim()),
      height: int.tryParse(_heightController.text.trim()),
      weight: int.tryParse(_weightController.text.trim()),
      nationality: _nationalityController.text.trim().isEmpty
          ? null
          : _nationalityController.text.trim(),
      growthType: _growthType,
      speed: _speed,
      power: _power,
      technique: _technique,
      pkAbility: _pkAbility,
      fkAbility: _fkAbility,
      ckAbility: _ckAbility,
      leadership: _leadership,
      intelligenceSense: _intelligenceSense,
      individualOrganization: _individualOrganization,
      portraitUrl: _portraitUrlController.text.trim().isEmpty
          ? null
          : _portraitUrlController.text.trim(),
      seedNames: _seedNamesController.text
          .split(RegExp(r'[;；|]'))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);

    try {
      final player = _buildPlayer(id: widget.playerId);
      if (widget.isEditing) {
        await widget.playerService.update(player);
      } else {
        await widget.playerService.create(player);
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isEditing ? '수정되었습니다.' : '등록되었습니다.')),
      );
      context.go('/admin');
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? '선수 수정' : '선수 추가'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('저장'),
          ),
        ],
      ),
      body: _initialLoading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _loadPlayer)
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 960),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SectionCard(
                              title: '기본 정보',
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      labelText: '이름 *',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return '이름을 입력하세요';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _fakeNameController,
                                    decoration: const InputDecoration(
                                      labelText: '가명',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<PlayerPosition>(
                                    initialValue: _position,
                                    decoration: const InputDecoration(
                                      labelText: '포지션',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: PlayerPosition.values
                                        .map(
                                          (position) => DropdownMenuItem(
                                            value: position,
                                            child: Text(position.label),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() => _position = value);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _ageStageController,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: '현재나이',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _peakAgeController,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: '전성기 나이 (참고)',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _rankController,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: '랭크',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _heightController,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: '키 (cm)',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _weightController,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: '몸무게 (kg)',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _nationalityController,
                                    decoration: const InputDecoration(
                                      labelText: '국적',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _seedNamesController,
                                    decoration: const InputDecoration(
                                      labelText: '시드 카테고리 (; 구분 · 여러 개 가능)',
                                      hintText: '일반시드; 2026 월드컵 대한민국 선발',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _portraitUrlController,
                                    decoration: const InputDecoration(
                                      labelText: 'portrait_url',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SectionCard(
                              title: '능력치',
                              child: Column(
                                children: [
                                  StatSliderField(
                                    label: '스피드',
                                    value: _speed,
                                    onChanged: (value) => setState(() => _speed = value),
                                  ),
                                  StatSliderField(
                                    label: '파워',
                                    value: _power,
                                    onChanged: (value) => setState(() => _power = value),
                                  ),
                                  StatSliderField(
                                    label: '기술',
                                    value: _technique,
                                    onChanged: (value) => setState(() => _technique = value),
                                  ),
                                  StatSliderField(
                                    label: 'PK',
                                    value: _pkAbility,
                                    onChanged: (value) => setState(() => _pkAbility = value),
                                  ),
                                  StatSliderField(
                                    label: 'FK',
                                    value: _fkAbility,
                                    onChanged: (value) => setState(() => _fkAbility = value),
                                  ),
                                  StatSliderField(
                                    label: 'CK',
                                    value: _ckAbility,
                                    onChanged: (value) => setState(() => _ckAbility = value),
                                  ),
                                  StatSliderField(
                                    label: '리더십',
                                    value: _leadership,
                                    onChanged: (value) => setState(() => _leadership = value),
                                  ),
                                  StatSliderField(
                                    label: '지력↔감각 (0=지력10, 10=감각10)',
                                    value: _intelligenceSense,
                                    onChanged: (value) =>
                                        setState(() => _intelligenceSense = value),
                                  ),
                                  StatSliderField(
                                    label: '개인↔조직 (0=개인10, 10=조직10)',
                                    value: _individualOrganization,
                                    onChanged: (value) =>
                                        setState(() => _individualOrganization = value),
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
                                    SizedBox(
                                      width: 140,
                                      child: TextFormField(
                                        initialValue: '${_positionFit[i] ?? 0}',
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: 'P$i',
                                          border: const OutlineInputBorder(),
                                        ),
                                        onChanged: (value) {
                                          final parsed = int.tryParse(value) ?? 0;
                                          _positionFit[i] = parsed.clamp(0, 10);
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SectionCard(
                              title: '성장 타입 (1기~10기)',
                              child: Column(
                                children: [
                                  for (var i = 0; i < Player.growthPeriodCount; i++)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${i + 1}기'),
                                          StatSliderField(
                                            label: '스피드',
                                            value: _growthType[i].speed,
                                            onChanged: (value) {
                                              setState(() {
                                                _growthType[i] =
                                                    _growthType[i].copyWith(speed: value);
                                              });
                                            },
                                          ),
                                          StatSliderField(
                                            label: '파워',
                                            value: _growthType[i].power,
                                            onChanged: (value) {
                                              setState(() {
                                                _growthType[i] =
                                                    _growthType[i].copyWith(power: value);
                                              });
                                            },
                                          ),
                                          StatSliderField(
                                            label: '기술',
                                            value: _growthType[i].technique,
                                            onChanged: (value) {
                                              setState(() {
                                                _growthType[i] =
                                                    _growthType[i].copyWith(technique: value);
                                              });
                                            },
                                          ),
                                          const Divider(),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            FilledButton(
                              onPressed: _loading ? null : _save,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(widget.isEditing ? '수정 저장' : '선수 등록'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
