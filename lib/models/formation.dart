class Formation {
  const Formation({
    required this.id,
    required this.name,
    this.tacticalType,
    this.keyPos1,
    this.keyPos2,
    this.keyPos3,
    this.comment,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? tacticalType;
  final String? keyPos1;
  final String? keyPos2;
  final String? keyPos3;
  final String? comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  List<String> get keyPositionIds =>
      [keyPos1, keyPos2, keyPos3].whereType<String>().where((id) => id.isNotEmpty).toList();

  factory Formation.fromJson(Map<String, dynamic> json) {
    return Formation(
      id: json['id'] as String? ?? json['formation_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      tacticalType: json['tactical_type'] as String?,
      keyPos1: json['key_pos_1'] as String?,
      keyPos2: json['key_pos_2'] as String?,
      keyPos3: json['key_pos_3'] as String?,
      comment: json['comment'] as String?,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    return {
      if (includeId && id.isNotEmpty) 'id': id,
      'name': name,
      'tactical_type': tacticalType,
      'key_pos_1': keyPos1,
      'key_pos_2': keyPos2,
      'key_pos_3': keyPos3,
      'comment': comment,
    };
  }

  Formation copyWith({
    String? id,
    String? name,
    String? tacticalType,
    String? keyPos1,
    String? keyPos2,
    String? keyPos3,
    String? comment,
  }) {
    return Formation(
      id: id ?? this.id,
      name: name ?? this.name,
      tacticalType: tacticalType ?? this.tacticalType,
      keyPos1: keyPos1 ?? this.keyPos1,
      keyPos2: keyPos2 ?? this.keyPos2,
      keyPos3: keyPos3 ?? this.keyPos3,
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
