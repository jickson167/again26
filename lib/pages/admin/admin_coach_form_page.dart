import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/coach.dart';
import '../../models/coach_master.dart';
import '../../services/app_services.dart';
import '../../utils/portrait_upload_target.dart';

class AdminCoachFormPage extends StatefulWidget {
  const AdminCoachFormPage({super.key, required this.services, this.coachId});

  final AppServices services;
  final String? coachId;

  bool get isEditing => coachId != null;

  @override
  State<AdminCoachFormPage> createState() => _AdminCoachFormPageState();
}

class _AdminCoachFormPageState extends State<AdminCoachFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _fakeNameController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _ageController = TextEditingController();
  final _rankController = TextEditingController();
  final _coachTypeController = TextEditingController();
  final _baseLeadershipController = TextEditingController();
  final _abilityIdController = TextEditingController();
  final _abilityNameController = TextEditingController();
  final _abilityEffectController = TextEditingController();
  final _fitGoodController = TextEditingController();
  final _fitNormalController = TextEditingController();
  final _fitBadController = TextEditingController();
  final _leadershipCurveController = TextEditingController();
  final _commentController = TextEditingController();
  final _portraitUrlController = TextEditingController();

  List<CoachAbility> _abilities = [];
  List<CoachStyle> _styles = [];
  bool _initialLoading = false;
  bool _saving = false;
  String? _error;
  String? _selectedPortraitDataUrl;
  String? _portraitMappingHint;

  @override
  void initState() {
    super.initState();
    _leadershipCurveController.text = Coach.defaultLeadershipCurve().join('|');
    _loadInitialData();
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _fakeNameController.dispose();
    _nationalityController.dispose();
    _ageController.dispose();
    _rankController.dispose();
    _coachTypeController.dispose();
    _baseLeadershipController.dispose();
    _abilityIdController.dispose();
    _abilityNameController.dispose();
    _abilityEffectController.dispose();
    _fitGoodController.dispose();
    _fitNormalController.dispose();
    _fitBadController.dispose();
    _leadershipCurveController.dispose();
    _commentController.dispose();
    _portraitUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _initialLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.services.coachMasterService.fetchAbilities(),
        widget.services.coachMasterService.fetchStyles(),
        if (widget.isEditing)
          widget.services.coachService.fetchById(widget.coachId!),
      ]);
      if (!mounted) {
        return;
      }

      _abilities = results[0] as List<CoachAbility>;
      _styles = results[1] as List<CoachStyle>;

      if (widget.isEditing) {
        final coach = results[2] as Coach?;
        if (coach == null) {
          setState(() {
            _error = '감독을 찾을 수 없습니다.';
            _initialLoading = false;
          });
          return;
        }
        _applyCoach(coach);
      } else {
        _applyMasterDefaults();
      }

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

  void _applyMasterDefaults() {
    if (_styles.isNotEmpty && _coachTypeController.text.trim().isEmpty) {
      _coachTypeController.text = _styles.first.name;
    }
    if (_abilities.isNotEmpty && _abilityIdController.text.trim().isEmpty) {
      _applyAbility(_abilities.first);
    }
  }

  void _applyAbility(CoachAbility ability) {
    _abilityIdController.text = ability.id;
    _abilityNameController.text = ability.name;
    _abilityEffectController.text = ability.effectForRank(_currentRank);
  }

  int get _currentRank => (_parseInt(_rankController.text) ?? 1).clamp(1, 5);

  void _refreshAbilityEffectForRank() {
    final ability = _selectedAbility;
    if (ability == null) {
      return;
    }
    _abilityEffectController.text = ability.effectForRank(_currentRank);
  }

  CoachAbility? get _selectedAbility {
    for (final ability in _abilities) {
      if (ability.id == _abilityIdController.text) {
        return ability;
      }
    }
    return null;
  }

  CoachStyle? get _selectedStyle {
    for (final style in _styles) {
      if (style.name == _coachTypeController.text) {
        return style;
      }
    }
    return null;
  }

  void _applyCoach(Coach coach) {
    _idController.text = coach.id;
    _nameController.text = coach.name;
    _fakeNameController.text = coach.fakeName ?? '';
    _nationalityController.text = coach.nationality ?? '';
    _ageController.text = coach.age?.toString() ?? '';
    _rankController.text = coach.rank?.toString() ?? '';
    _coachTypeController.text = coach.coachType;
    _baseLeadershipController.text = '${coach.baseLeadership}';
    _abilityIdController.text = coach.abilityId;
    _abilityNameController.text = coach.abilityName;
    _abilityEffectController.text = coach.abilityEffect;
    _fitGoodController.text = coach.fitGood.join('|');
    _fitNormalController.text = coach.fitNormal.join('|');
    _fitBadController.text = coach.fitBad.join('|');
    _leadershipCurveController.text = coach.leadershipCurve.join('|');
    _commentController.text = coach.comment ?? '';
    _portraitUrlController.text = coach.portraitUrl ?? '';
    _selectedPortraitDataUrl = null;
    _portraitMappingHint = null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      final coach = _buildCoach();
      if (widget.isEditing) {
        await widget.services.coachService.update(coach);
      } else {
        await widget.services.coachService.create(coach);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? '수정되었습니다.' : '등록되었습니다.'),
          ),
        );
        if (Navigator.of(context).canPop()) {
          context.pop(true);
        } else {
          final token = DateTime.now().millisecondsSinceEpoch.toString();
          context.go('/admin?tab=coach&coachesRefresh=$token');
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickPortraitImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지 바이트를 읽지 못했습니다. 다시 선택해 주세요.')),
      );
      return;
    }

    final entityId = widget.isEditing
        ? (widget.coachId ?? '').trim()
        : _idController.text.trim();
    final target = PortraitUploadTarget.forEntity(
      entityId: entityId.isEmpty ? 'coach' : entityId,
      sourceFileName: file.name,
      directory: 'coach_images',
    );

    final mimeType = _mimeTypeFor(file.name, file.extension);
    final dataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';

    setState(() {
      _selectedPortraitDataUrl = dataUrl;
      _portraitMappingHint = '선택한 파일: ${file.name} → ${target.fileName}';
    });
  }

  String _mimeTypeFor(String fileName, String? extension) {
    final ext = (extension ?? '').toLowerCase();
    if (ext == 'jpg' || ext == 'jpeg') {
      return 'image/jpeg';
    }
    if (ext == 'webp') {
      return 'image/webp';
    }
    if (ext == 'gif') {
      return 'image/gif';
    }
    if (ext == 'bmp') {
      return 'image/bmp';
    }
    if (ext == 'avif') {
      return 'image/avif';
    }

    final lower = fileName.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.gif')) {
      return 'image/gif';
    }
    if (lower.endsWith('.bmp')) {
      return 'image/bmp';
    }
    if (lower.endsWith('.avif')) {
      return 'image/avif';
    }
    return 'image/png';
  }

  Coach _buildCoach() {
    return Coach(
      id: _idController.text.trim(),
      name: _nameController.text.trim(),
      fakeName: _nullable(_fakeNameController.text),
      nationality: _nullable(_nationalityController.text),
      age: _parseInt(_ageController.text),
      rank: _parseInt(_rankController.text)?.clamp(1, 5),
      coachType: _coachTypeController.text.trim(),
      baseLeadership: (_parseInt(_baseLeadershipController.text) ?? 0).clamp(
        0,
        100,
      ),
      abilityId: _abilityIdController.text.trim(),
      abilityName: _abilityNameController.text.trim(),
      abilityEffect: _abilityEffectController.text.trim(),
      fitGood: _splitList(_fitGoodController.text),
      fitNormal: _splitList(_fitNormalController.text),
      fitBad: _splitList(_fitBadController.text),
      leadershipCurve: _parseCurve(_leadershipCurveController.text),
      comment: _nullable(_commentController.text),
      portraitUrl:
          _selectedPortraitDataUrl ??
          (_portraitUrlController.text.trim().isEmpty
              ? null
              : _portraitUrlController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? '감독 수정' : '감독 추가'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: _error != null
          ? Center(child: Text(_error!))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _TextField(
                    controller: _idController,
                    label: 'coach_id',
                    enabled: !widget.isEditing,
                    validator: _requiredCoachId,
                  ),
                  _TextField(
                    controller: _nameController,
                    label: '이름',
                    validator: _required,
                  ),
                  _TextField(controller: _fakeNameController, label: '가명'),
                  _TextField(controller: _nationalityController, label: '국적'),
                  _TextField(
                    controller: _ageController,
                    label: '나이',
                    keyboardType: TextInputType.number,
                  ),
                  _TextField(
                    controller: _rankController,
                    label: '랭크(1~5)',
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _refreshAbilityEffectForRank(),
                  ),
                  _CoachStylePicker(
                    styles: _styles,
                    selectedStyle: _selectedStyle,
                    controller: _coachTypeController,
                    onChanged: (style) {
                      setState(() {
                        _coachTypeController.text = style.name;
                      });
                    },
                  ),
                  _TextField(
                    controller: _baseLeadershipController,
                    label: '기본 통솔력(0~100)',
                    keyboardType: TextInputType.number,
                    validator: _required,
                  ),
                  _CoachAbilityPicker(
                    abilities: _abilities,
                    selectedAbility: _selectedAbility,
                    onChanged: (ability) {
                      setState(() => _applyAbility(ability));
                    },
                  ),
                  _TextField(
                    controller: _abilityIdController,
                    label: '고유능력 ID',
                    validator: _required,
                  ),
                  _TextField(
                    controller: _abilityNameController,
                    label: '고유능력 이름',
                    validator: _required,
                  ),
                  _TextField(
                    controller: _abilityEffectController,
                    label: '고유능력 효과',
                    maxLines: 2,
                    validator: _required,
                  ),
                  _TextField(
                    controller: _fitGoodController,
                    label: '높은 적합 포메이션(| 구분)',
                  ),
                  _TextField(
                    controller: _fitNormalController,
                    label: '보통 적합 포메이션(| 구분)',
                  ),
                  _TextField(
                    controller: _fitBadController,
                    label: '낮은 적합 포메이션(| 구분)',
                  ),
                  _TextField(
                    controller: _leadershipCurveController,
                    label: '통솔력 곡선 18개(| 구분, 18기는 0)',
                    maxLines: 2,
                    validator: _validateCurve,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _saving ? null : _pickPortraitImage,
                        icon: const Icon(Icons.image_outlined),
                        label: const Text('감독 이미지 업로드'),
                      ),
                    ],
                  ),
                  if (_portraitMappingHint != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _portraitMappingHint!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _TextField(
                    controller: _portraitUrlController,
                    label: 'portrait_url',
                    maxLines: 2,
                  ),
                  Text(
                    '업로드한 파일은 감독 ID 기반 이미지로 자동 매핑됩니다.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  _TextField(
                    controller: _commentController,
                    label: '설명',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_saving ? '저장 중...' : '저장'),
                  ),
                ],
              ),
            ),
    );
  }

  static String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '필수 입력입니다.';
    }
    return null;
  }

  static String? _requiredCoachId(String? value) {
    final required = _required(value);
    if (required != null) {
      return required;
    }
    if (!value!.trim().startsWith('ch_')) {
      return 'ch_ 로 시작해야 합니다.';
    }
    return null;
  }

  static String? _validateCurve(String? value) {
    final curve = _parseCurve(value ?? '');
    if (curve.length != Coach.leadershipPeriodCount) {
      return '18개 값이 필요합니다.';
    }
    if (curve.last != 0) {
      return '18기 값은 0이어야 합니다.';
    }
    return null;
  }

  static String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int? _parseInt(String value) {
    return int.tryParse(value.trim());
  }

  static List<String> _splitList(String value) {
    return value
        .split(RegExp(r'[|;；,]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static List<int> _parseCurve(String value) {
    return value
        .split(RegExp(r'[|;；,]'))
        .map((item) => int.tryParse(item.trim())?.clamp(0, 100) ?? 0)
        .toList();
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    this.enabled = true,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _CoachStylePicker extends StatelessWidget {
  const _CoachStylePicker({
    required this.styles,
    required this.selectedStyle,
    required this.controller,
    required this.onChanged,
  });

  final List<CoachStyle> styles;
  final CoachStyle? selectedStyle;
  final TextEditingController controller;
  final ValueChanged<CoachStyle> onChanged;

  @override
  Widget build(BuildContext context) {
    if (styles.isEmpty) {
      return _TextField(
        controller: controller,
        label: '감독 유형',
        validator: _AdminCoachFormPageState._required,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: selectedStyle?.id,
        decoration: InputDecoration(
          labelText: '감독 스타일',
          helperText: selectedStyle?.description,
          border: const OutlineInputBorder(),
        ),
        items: [
          for (final style in styles)
            DropdownMenuItem(value: style.id, child: Text(style.name)),
        ],
        onChanged: (id) {
          if (id == null) return;
          for (final style in styles) {
            if (style.id == id) {
              onChanged(style);
              break;
            }
          }
        },
      ),
    );
  }
}

class _CoachAbilityPicker extends StatelessWidget {
  const _CoachAbilityPicker({
    required this.abilities,
    required this.selectedAbility,
    required this.onChanged,
  });

  final List<CoachAbility> abilities;
  final CoachAbility? selectedAbility;
  final ValueChanged<CoachAbility> onChanged;

  @override
  Widget build(BuildContext context) {
    if (abilities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: selectedAbility?.id,
        decoration: InputDecoration(
          labelText: '고유능력 선택',
          helperText: selectedAbility?.baseEffect,
          border: const OutlineInputBorder(),
        ),
        items: [
          for (final ability in abilities)
            DropdownMenuItem(
              value: ability.id,
              child: Text('${ability.name} (${ability.id})'),
            ),
        ],
        onChanged: (id) {
          if (id == null) return;
          for (final ability in abilities) {
            if (ability.id == id) {
              onChanged(ability);
              break;
            }
          }
        },
      ),
    );
  }
}
