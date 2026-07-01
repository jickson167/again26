import 'player_growth.dart';
import 'player_position.dart';

class Player {
  const Player({
    required this.id,
    required this.name,
    this.fakeName,
    required this.position,
    required this.positionFit,
    this.rank,
    this.ageStage,
    this.height,
    this.weight,
    this.nationality,
    required this.growthType,
    required this.speed,
    required this.power,
    required this.technique,
    required this.pkAbility,
    required this.fkAbility,
    required this.ckAbility,
    required this.leadership,
    required this.intelligenceSense,
    required this.individualOrganization,
    this.portraitUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? fakeName;
  final PlayerPosition position;
  final Map<int, int> positionFit;
  final int? rank;
  final String? ageStage;
  final int? height;
  final int? weight;
  final String? nationality;
  final List<PlayerGrowth> growthType;
  final int speed;
  final int power;
  final int technique;
  final int pkAbility;
  final int fkAbility;
  final int ckAbility;
  final int leadership;
  final int intelligenceSense;
  final int individualOrganization;
  final String? portraitUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static const positionFitCount = 13;
  static const growthPeriodCount = 10;

  factory Player.empty({String? id}) {
    return Player(
      id: id ?? '',
      name: '',
      position: PlayerPosition.mf,
      positionFit: defaultPositionFit(),
      growthType: defaultGrowthType(),
      speed: 0,
      power: 0,
      technique: 0,
      pkAbility: 0,
      fkAbility: 0,
      ckAbility: 0,
      leadership: 0,
      intelligenceSense: 5,
      individualOrganization: 5,
    );
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      fakeName: json['fake_name'] as String?,
      position: PlayerPosition.fromCode(json['position'] as String?),
      positionFit: _parsePositionFit(json['position_fit']),
      rank: json['rank'] as int?,
      ageStage: json['age_stage'] as String?,
      height: json['height'] as int?,
      weight: json['weight'] as int?,
      nationality: json['nationality'] as String?,
      growthType: _parseGrowthType(json['growth_type']),
      speed: _clampStat(json['speed']),
      power: _clampStat(json['power']),
      technique: _clampStat(json['technique']),
      pkAbility: _clampStat(json['pk_ability']),
      fkAbility: _clampStat(json['fk_ability']),
      ckAbility: _clampStat(json['ck_ability']),
      leadership: _clampStat(json['leadership']),
      intelligenceSense: _clampStat(json['intelligence_sense'], defaultValue: 5),
      individualOrganization:
          _clampStat(json['individual_organization'], defaultValue: 5),
      portraitUrl: json['portrait_url'] as String?,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    return {
      if (includeId && id.isNotEmpty) 'id': id,
      'name': name,
      'fake_name': fakeName,
      'position': position.code,
      'position_fit': positionFit.map((key, value) => MapEntry('$key', value)),
      'rank': rank,
      'age_stage': ageStage,
      'height': height,
      'weight': weight,
      'nationality': nationality,
      'growth_type': growthType.map((growth) => growth.toJson()).toList(),
      'speed': speed,
      'power': power,
      'technique': technique,
      'pk_ability': pkAbility,
      'fk_ability': fkAbility,
      'ck_ability': ckAbility,
      'leadership': leadership,
      'intelligence_sense': intelligenceSense,
      'individual_organization': individualOrganization,
      'portrait_url': portraitUrl,
    };
  }

  Player copyWith({
    String? id,
    String? name,
    String? fakeName,
    PlayerPosition? position,
    Map<int, int>? positionFit,
    int? rank,
    String? ageStage,
    int? height,
    int? weight,
    String? nationality,
    List<PlayerGrowth>? growthType,
    int? speed,
    int? power,
    int? technique,
    int? pkAbility,
    int? fkAbility,
    int? ckAbility,
    int? leadership,
    int? intelligenceSense,
    int? individualOrganization,
    String? portraitUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      fakeName: fakeName ?? this.fakeName,
      position: position ?? this.position,
      positionFit: positionFit ?? this.positionFit,
      rank: rank ?? this.rank,
      ageStage: ageStage ?? this.ageStage,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      nationality: nationality ?? this.nationality,
      growthType: growthType ?? this.growthType,
      speed: speed ?? this.speed,
      power: power ?? this.power,
      technique: technique ?? this.technique,
      pkAbility: pkAbility ?? this.pkAbility,
      fkAbility: fkAbility ?? this.fkAbility,
      ckAbility: ckAbility ?? this.ckAbility,
      leadership: leadership ?? this.leadership,
      intelligenceSense: intelligenceSense ?? this.intelligenceSense,
      individualOrganization:
          individualOrganization ?? this.individualOrganization,
      portraitUrl: portraitUrl ?? this.portraitUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get intelligenceValue => 10 - intelligenceSense;
  int get senseValue => intelligenceSense;
  int get individualValue => 10 - individualOrganization;
  int get organizationValue => individualOrganization;

  static Map<int, int> defaultPositionFit() {
    return {
      for (var i = 1; i <= positionFitCount; i++) i: 0,
    };
  }

  static List<PlayerGrowth> defaultGrowthType() {
    return List.generate(growthPeriodCount, (_) => PlayerGrowth.empty());
  }

  static Map<int, int> _parsePositionFit(dynamic raw) {
    final result = defaultPositionFit();
    if (raw is! Map) {
      return result;
    }

    raw.forEach((key, value) {
      final index = int.tryParse('$key');
      if (index != null && index >= 1 && index <= positionFitCount) {
        result[index] = _clampStat(value);
      }
    });
    return result;
  }

  static List<PlayerGrowth> _parseGrowthType(dynamic raw) {
    if (raw is! List) {
      return defaultGrowthType();
    }

    final parsed = raw
        .map((item) => PlayerGrowth.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    while (parsed.length < growthPeriodCount) {
      parsed.add(PlayerGrowth.empty());
    }

    if (parsed.length > growthPeriodCount) {
      return parsed.sublist(0, growthPeriodCount);
    }

    return parsed;
  }

  static int _clampStat(dynamic value, {int defaultValue = 0}) {
    final parsed = value is int ? value : int.tryParse('$value') ?? defaultValue;
    return parsed.clamp(0, 10);
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse('$value');
  }
}
