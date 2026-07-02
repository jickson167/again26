import '../models/formation.dart';

/// CSV import 버그 등으로 깨진 포메이션 데이터를 화면용으로 정리
class FormationDisplay {
  FormationDisplay(this.formation);

  final Formation formation;

  String get name => _extractFormationName();
  String get comment => _extractComment();
  List<String> get keyPositionIds => formation.keyPositionIds;

  bool get needsReimport => isCorruptRecord(formation);

  /// 옛 CSV 버그로 한 줄 전체가 필드에 들어간 row
  static bool isCorruptRecord(Formation formation) {
    return _looksCorruptValue(formation.id) ||
        _looksCorruptValue(formation.name) ||
        _looksCorruptValue(formation.keyPos1 ?? '') ||
        _looksCorruptValue(formation.keyPos2 ?? '') ||
        _looksCorruptValue(formation.keyPos3 ?? '') ||
        _looksCorruptValue(formation.comment ?? '');
  }

  static bool _looksCorruptValue(String value) {
    if (value.isEmpty) {
      return false;
    }
    if (value.contains('[index]')) {
      return true;
    }
    if (value.startsWith('[') && value.contains('fm_')) {
      return true;
    }
    return value.contains(',') && value.contains('fm_') && value.contains('kp_');
  }

  String _extractFormationName() {
    final raw = formation.name.trim();
    if (!_looksCorrupt(raw)) {
      return raw;
    }
    for (final part in _splitParts(raw)) {
      if (RegExp(r'^\d+(?:-\d+)+$').hasMatch(part)) {
        return part;
      }
    }
    return '포메이션';
  }

  String _extractComment() {
    final raw = formation.comment?.trim() ?? '';
    if (raw.isNotEmpty && !_looksCorrupt(raw) && !raw.contains('kp_')) {
      return raw;
    }
    for (final part in _splitParts(raw.isNotEmpty ? raw : formation.name)) {
      if (part.contains('kp_') || part.startsWith('fm_')) {
        continue;
      }
      if (RegExp(r'^\d+(?:-\d+)+$').hasMatch(part)) {
        continue;
      }
      if (RegExp(r'[가-힣]').hasMatch(part) && part.length > 6) {
        return part;
      }
    }
    return '';
  }

  bool _looksCorrupt(String value) {
    return _looksCorruptValue(value);
  }

  List<String> _splitParts(String raw) {
    return raw
        .replaceAll('[index]', '')
        .replaceAll('[', '')
        .replaceAll(']', '')
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }
}
