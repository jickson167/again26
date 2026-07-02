/// 포메이션 이름(예: 4-1-4-1) → 13칸 슬롯 중 선수가 서는 위치
class FormationShape {
  FormationShape._();

  /// 포메이션별 고정 슬롯 (GK 13 포함, 총 11명)
  static const _templates = {
    '4-4-2': [10, 11, 12, 9, 4, 5, 6, 8, 1, 3, 13],
    '4-3-3': [10, 11, 12, 9, 4, 8, 6, 1, 2, 3, 13],
    '4-2-3-1': [10, 11, 12, 9, 8, 7, 4, 5, 6, 2, 13],
    '3-4-1-2': [10, 11, 12, 7, 4, 6, 9, 5, 1, 3, 13],
    '3-5-2': [10, 11, 12, 7, 4, 5, 6, 9, 1, 3, 13],
    '3-4-3': [10, 11, 12, 7, 4, 6, 9, 1, 2, 3, 13],
    '4-1-4-1': [10, 11, 12, 9, 8, 4, 5, 6, 7, 2, 13],
    '4-5-1': [10, 11, 12, 9, 4, 5, 8, 6, 7, 2, 13],
    '4-3-1-2': [10, 11, 12, 9, 4, 8, 6, 5, 2, 3, 13],
    '4-1-2-1-2': [10, 11, 12, 9, 8, 4, 6, 5, 1, 3, 13],
    '5-3-2': [7, 10, 11, 12, 9, 4, 8, 6, 1, 3, 13],
    '5-4-1': [7, 10, 11, 12, 9, 4, 5, 6, 8, 2, 13],
    '3-2-4-1': [10, 11, 12, 8, 7, 4, 5, 6, 3, 2, 13],
    '4-2-2-2': [10, 11, 12, 9, 8, 5, 4, 6, 2, 3, 13],
    '4-2-4': [10, 11, 12, 9, 8, 5, 1, 2, 3, 6, 13],
  };

  static String? normalizeName(String formationName) {
    final match = RegExp(r'\d+(?:-\d+)+').firstMatch(formationName.trim());
    return match?.group(0);
  }

  static List<int> parseLineCounts(String formationName) {
    final normalized = normalizeName(formationName);
    if (normalized == null) {
      return [4, 4, 2];
    }
    return normalized.split('-').map(int.parse).toList();
  }

  /// GK(13) 포함, 포메이션에 해당하는 슬롯만 반환
  static Set<int> occupiedSlots(String formationName) {
    final normalized = normalizeName(formationName);
    if (normalized != null && _templates.containsKey(normalized)) {
      return _templates[normalized]!.toSet();
    }
    return _fallbackSlots(parseLineCounts(formationName));
  }

  static Set<int> _fallbackSlots(List<int> lines) {
    if (lines.isEmpty) {
      return {13};
    }

    final slots = <int>{13};
    final pools = switch (lines.length) {
      3 => [
          const [10, 11, 12],
          const [7, 4, 5, 6, 9],
          const [1, 3],
        ],
      4 => [
          const [10, 11, 12, 9],
          const [8],
          const [4, 5, 6, 7],
          const [2],
        ],
      5 => [
          const [10, 11, 12],
          const [7, 9],
          const [4, 5, 6],
          const [8],
          const [2],
        ],
      _ => [
          const [10, 11, 12],
          const [7, 8, 9],
          const [4, 5, 6],
          const [1, 2, 3],
        ],
    };

    for (var i = 0; i < lines.length && i < pools.length; i++) {
      _addDistinct(slots, lines[i], pools[i]);
    }
    return slots;
  }

  static void _addDistinct(Set<int> slots, int count, List<int> pool) {
    if (count <= 0) {
      return;
    }
    if (count >= pool.length) {
      slots.addAll(pool);
      return;
    }
    if (count == 1) {
      slots.add(pool[pool.length ~/ 2]);
      return;
    }
    for (var i = 0; i < count; i++) {
      final idx = (i * (pool.length - 1) / (count - 1)).round();
      slots.add(pool[idx]);
    }
  }
}
