import '../models/formation.dart';

/// CSV import 버그 등으로 깨진 포메이션 데이터를 화면용으로 정리
class FormationDisplay {
  FormationDisplay(this.formation);

  final Formation formation;

  String get name => _extractFormationName();
  String get tacticalType => _extractTacticalType();
  String get comment => _extractComment();
  List<String> get keyPositionIds => _extractKeyPositionIds();

  bool get needsReimport =>
      formation.name.contains('[') ||
      formation.name.contains(',') ||
      (formation.comment?.contains('kp_') ?? false);

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

  String _extractTacticalType() {
    final raw = formation.tacticalType?.trim() ?? '';
    if (raw.isNotEmpty && !_looksCorrupt(raw) && !raw.startsWith('kp_')) {
      return raw;
    }
    for (final part in _splitParts('${formation.name},${formation.tacticalType},${formation.comment}')) {
      if (part.contains('kp_') || part.startsWith('fm_')) {
        continue;
      }
      if (RegExp(r'^\d+(?:-\d+)+$').hasMatch(part)) {
        continue;
      }
      if (RegExp(r'[가-힣]').hasMatch(part) && part.length <= 12) {
        return part;
      }
    }
    return raw.isEmpty ? '전술' : raw;
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

  List<String> _extractKeyPositionIds() {
    final fromFields = formation.keyPositionIds;
    if (fromFields.length == 3 &&
        fromFields.every((id) => !id.contains(',') && !id.contains('['))) {
      return fromFields;
    }

    final ids = <String>[];
    for (final raw in [
      formation.keyPos1,
      formation.keyPos2,
      formation.keyPos3,
      formation.name,
      formation.comment,
    ]) {
      if (raw == null || raw.isEmpty) {
        continue;
      }
      for (final match in RegExp(r'kp_[a-z0-9_]+').allMatches(raw)) {
        final id = match.group(0)!;
        if (!ids.contains(id)) {
          ids.add(id);
        }
      }
      if (ids.length >= 3) {
        break;
      }
    }
    return ids.take(3).toList();
  }

  bool _looksCorrupt(String value) {
    return value.contains('[') || value.contains(',') || value.contains('[index]');
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

  /// "3-2-4-1" → [3, 2, 4, 1] (수비선→공격선)
  List<int> get lineCounts {
    final match = RegExp(r'\d+(?:-\d+)+').firstMatch(name);
    if (match == null) {
      return [4, 4, 2];
    }
    return match.group(0)!.split('-').map(int.parse).toList();
  }
}
