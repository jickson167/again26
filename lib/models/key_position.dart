import 'player_position.dart';

class KeyPosition {
  const KeyPosition({
    required this.id,
    required this.name,
    required this.simplePosition,
    required this.mainStat,
    required this.subStat,
    required this.mentalPref,
    required this.teamPref,
    this.description,
    this.comment,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final PlayerPosition simplePosition;
  final String mainStat;
  final String subStat;
  final String mentalPref;
  final String teamPref;
  final String? description;
  final String? comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory KeyPosition.fromJson(Map<String, dynamic> json) {
    return KeyPosition(
      id: json['id'] as String? ?? json['key_position_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      simplePosition: PlayerPosition.fromCode(json['simple_position'] as String?),
      mainStat: json['main_stat'] as String? ?? '',
      subStat: json['sub_stat'] as String? ?? '',
      mentalPref: json['mental_pref'] as String? ?? 'intelligence',
      teamPref: json['team_pref'] as String? ?? 'organization',
      description: json['description'] as String?,
      comment: json['comment'] as String?,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    return {
      if (includeId && id.isNotEmpty) 'id': id,
      'name': name,
      'simple_position': simplePosition.code,
      'main_stat': mainStat,
      'sub_stat': subStat,
      'mental_pref': mentalPref,
      'team_pref': teamPref,
      'description': description,
      'comment': comment,
    };
  }

  KeyPosition copyWith({
    String? id,
    String? name,
    PlayerPosition? simplePosition,
    String? mainStat,
    String? subStat,
    String? mentalPref,
    String? teamPref,
    String? description,
    String? comment,
  }) {
    return KeyPosition(
      id: id ?? this.id,
      name: name ?? this.name,
      simplePosition: simplePosition ?? this.simplePosition,
      mainStat: mainStat ?? this.mainStat,
      subStat: subStat ?? this.subStat,
      mentalPref: mentalPref ?? this.mentalPref,
      teamPref: teamPref ?? this.teamPref,
      description: description ?? this.description,
      comment: comment ?? this.comment,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse('$value');
  }
}
