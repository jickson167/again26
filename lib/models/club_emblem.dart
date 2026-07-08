class ClubEmblem {
  const ClubEmblem({
    required this.id,
    required this.grade,
    required this.seedType,
    this.imageData,
    this.updatedAt,
  });

  final String id;
  final int grade;
  final String seedType;
  final String? imageData;
  final DateTime? updatedAt;

  ClubEmblem copyWith({
    String? id,
    int? grade,
    String? seedType,
    String? imageData,
    DateTime? updatedAt,
  }) {
    return ClubEmblem(
      id: id ?? this.id,
      grade: grade ?? this.grade,
      seedType: seedType ?? this.seedType,
      imageData: imageData ?? this.imageData,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ClubEmblem.fromJson(Map<String, dynamic> json) {
    return ClubEmblem(
      id: (json['id'] as String? ?? '').trim(),
      grade: (json['grade'] as num?)?.toInt() ?? 1,
      seedType: (json['seed_type'] as String? ?? '일반시드').trim(),
      imageData: (json['image_data'] as String?)?.trim(),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.tryParse(json['updated_at'].toString()),
    );
  }
}
