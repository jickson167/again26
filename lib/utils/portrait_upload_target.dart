class PortraitUploadTarget {
  const PortraitUploadTarget({
    required this.directory,
    required this.fileName,
    required this.relativePath,
  });

  final String directory;
  final String fileName;
  final String relativePath;

  factory PortraitUploadTarget.forEntity({
    required String entityId,
    required String sourceFileName,
    required String directory,
  }) {
    final sanitizedId = entityId.trim();
    final baseName = sanitizedId.isEmpty ? 'portrait' : sanitizedId;
    final extension = _extensionFrom(sourceFileName);
    final fileName = '$baseName.$extension';
    return PortraitUploadTarget(
      directory: directory,
      fileName: fileName,
      relativePath: '$directory/$fileName',
    );
  }

  static String _extensionFrom(String sourceFileName) {
    final trimmed = sourceFileName.trim();
    if (trimmed.isEmpty) {
      return 'png';
    }
    final match = RegExp(r'\.([A-Za-z0-9]+)$').firstMatch(trimmed);
    return match?.group(1)?.toLowerCase() ?? 'png';
  }
}
