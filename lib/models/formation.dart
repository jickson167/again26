import '../utils/formation_layout_grid.dart';

class Formation {
  const Formation({
    required this.id,
    required this.name,
    this.formationType,
    this.possession = 5,
    this.attack = 5,
    this.stability = 5,
    this.keyPos1,
    this.keyPos1Slot,
    this.keyPos2,
    this.keyPos2Slot,
    this.keyPos3,
    this.keyPos3Slot,
    this.comment,
    this.layoutOutfield,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? formationType;
  final int possession;
  final int attack;
  final int stability;
  final String? keyPos1;
  final int? keyPos1Slot;
  final String? keyPos2;
  final int? keyPos2Slot;
  final String? keyPos3;
  final int? keyPos3Slot;
  final String? comment;
  /// 필드 10명 레이아웃. null이면 FormationPitchLayout 폴백.
  final List<OutfieldLayoutPoint>? layoutOutfield;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  List<String> get keyPositionIds => [
        keyPos1,
        keyPos2,
        keyPos3,
      ].whereType<String>().where((id) => id.isNotEmpty).toList();

  List<int> get keyPositionSlots => [
        keyPos1Slot,
        keyPos2Slot,
        keyPos3Slot,
      ].whereType<int>().where((slot) => slot >= 1 && slot <= 13).toList();

  List<({String id, int slot})> get keyPositionEntries {
    final entries = <({String id, int slot})>[];
    void add(String? id, int? slot) {
      if (id == null || id.isEmpty || slot == null || slot < 1 || slot > 13) {
        return;
      }
      entries.add((id: id, slot: slot));
    }

    add(keyPos1, keyPos1Slot);
    add(keyPos2, keyPos2Slot);
    add(keyPos3, keyPos3Slot);
    return entries;
  }

  /// 편집/표시용 필드 10점.
  /// DB 레이아웃만 신뢰. 없으면 슬롯 매핑 기본(패널 중앙 cell=1).
  List<OutfieldLayoutPoint> resolvedLayoutOutfield() {
    final saved = layoutOutfield;
    if (saved != null && saved.length == 10) return List.of(saved);
    return FormationLayoutGrid.defaultFromFormationName(name);
  }

  String? get formationTypeLabel {
    return switch (formationType?.toUpperCase()) {
      'S' => 'Speed',
      'T' => 'Technique',
      'P' => 'Power',
      _ => null,
    };
  }

  factory Formation.fromJson(Map<String, dynamic> json) {
    return Formation(
      id: json['id'] as String? ?? json['formation_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      formationType: json['formation_type'] as String?,
      possession: _parseStat(json['possession']),
      attack: _parseStat(json['attack']),
      stability: _parseStat(json['stability']),
      keyPos1: json['key_pos_1'] as String?,
      keyPos1Slot: _parseSlot(json['key_pos_1_slot']),
      keyPos2: json['key_pos_2'] as String?,
      keyPos2Slot: _parseSlot(json['key_pos_2_slot']),
      keyPos3: json['key_pos_3'] as String?,
      keyPos3Slot: _parseSlot(json['key_pos_3_slot']),
      comment: json['comment'] as String?,
      layoutOutfield: FormationLayoutGrid.parseLayout(json['layout_outfield']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    return {
      if (includeId && id.isNotEmpty) 'id': id,
      'name': name,
      'formation_type': formationType,
      'possession': possession,
      'attack': attack,
      'stability': stability,
      'key_pos_1': keyPos1,
      'key_pos_1_slot': keyPos1Slot,
      'key_pos_2': keyPos2,
      'key_pos_2_slot': keyPos2Slot,
      'key_pos_3': keyPos3,
      'key_pos_3_slot': keyPos3Slot,
      'comment': comment,
      'layout_outfield': layoutOutfield == null
          ? null
          : FormationLayoutGrid.layoutToJson(layoutOutfield!),
    };
  }

  Formation copyWith({
    String? id,
    String? name,
    String? formationType,
    int? possession,
    int? attack,
    int? stability,
    String? keyPos1,
    int? keyPos1Slot,
    String? keyPos2,
    int? keyPos2Slot,
    String? keyPos3,
    int? keyPos3Slot,
    String? comment,
    List<OutfieldLayoutPoint>? layoutOutfield,
    bool clearLayoutOutfield = false,
  }) {
    return Formation(
      id: id ?? this.id,
      name: name ?? this.name,
      formationType: formationType ?? this.formationType,
      possession: possession ?? this.possession,
      attack: attack ?? this.attack,
      stability: stability ?? this.stability,
      keyPos1: keyPos1 ?? this.keyPos1,
      keyPos1Slot: keyPos1Slot ?? this.keyPos1Slot,
      keyPos2: keyPos2 ?? this.keyPos2,
      keyPos2Slot: keyPos2Slot ?? this.keyPos2Slot,
      keyPos3: keyPos3 ?? this.keyPos3,
      keyPos3Slot: keyPos3Slot ?? this.keyPos3Slot,
      comment: comment ?? this.comment,
      layoutOutfield:
          clearLayoutOutfield ? null : (layoutOutfield ?? this.layoutOutfield),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static int _parseStat(dynamic value) {
    if (value == null) {
      return 5;
    }
    return int.tryParse('$value')?.clamp(0, 10) ?? 5;
  }

  static int? _parseSlot(dynamic value) {
    if (value == null || '$value'.trim().isEmpty) {
      return null;
    }
    final slot = int.tryParse('$value');
    if (slot == null || slot < 1 || slot > 13) {
      return null;
    }
    return slot;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse('$value');
  }
}
