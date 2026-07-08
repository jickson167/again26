class NationFlagImage {
  const NationFlagImage({
    required this.nationality,
    required this.imageData,
    this.updatedAt,
  });

  final String nationality;
  final String imageData;
  final DateTime? updatedAt;

  factory NationFlagImage.fromJson(Map<String, dynamic> json) {
    return NationFlagImage(
      nationality: (json['nationality'] as String? ?? '').trim(),
      imageData: (json['image_data'] as String? ?? '').trim(),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.tryParse(json['updated_at'].toString()),
    );
  }
}
