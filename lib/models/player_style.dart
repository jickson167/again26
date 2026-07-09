enum PlayerStyleCategory {
  base('base', '기본 성향 스타일'),
  forward('forward', '공격수 / 윙어 스타일'),
  midfielder('midfielder', '미드필더 스타일'),
  defender('defender', '수비수 스타일'),
  goalkeeper('goalkeeper', '골키퍼 스타일');

  const PlayerStyleCategory(this.code, this.labelKo);

  final String code;
  final String labelKo;

  static PlayerStyleCategory fromCode(String? code) {
    return PlayerStyleCategory.values.firstWhere(
      (item) => item.code == code,
      orElse: () => PlayerStyleCategory.base,
    );
  }

  static List<PlayerStyleCategory> get ordered => PlayerStyleCategory.values;
}

class PlayerStyle {
  const PlayerStyle({
    required this.id,
    required this.category,
    required this.labelKo,
    this.sortOrder = 0,
    this.updatedAt,
  });

  final String id;
  final PlayerStyleCategory category;
  final String labelKo;
  final int sortOrder;
  final DateTime? updatedAt;

  factory PlayerStyle.fromJson(Map<String, dynamic> json) {
    return PlayerStyle(
      id: json['id'] as String,
      category: PlayerStyleCategory.fromCode(json['category'] as String?),
      labelKo: json['label_ko'] as String? ?? '',
      sortOrder: json['sort_order'] as int? ?? 0,
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category.code,
      'label_ko': labelKo,
      'sort_order': sortOrder,
    };
  }

  PlayerStyle copyWith({
    String? id,
    PlayerStyleCategory? category,
    String? labelKo,
    int? sortOrder,
    DateTime? updatedAt,
  }) {
    return PlayerStyle(
      id: id ?? this.id,
      category: category ?? this.category,
      labelKo: labelKo ?? this.labelKo,
      sortOrder: sortOrder ?? this.sortOrder,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) {
      return null;
    }
    return DateTime.tryParse('$raw');
  }
}

List<String> resolveStyleLabels({
  required List<String> styleIds,
  required Map<String, PlayerStyle> stylesById,
}) {
  return [
    for (final id in styleIds)
      if (stylesById[id] != null) stylesById[id]!.labelKo,
  ];
}
