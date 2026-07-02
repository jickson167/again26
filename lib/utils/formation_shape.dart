/// 포메이션 이름(예: 3-5-2) → 13칸 슬롯 중 선수가 서는 위치
class FormationShape {
  FormationShape._();

  static List<int> parseLineCounts(String formationName) {
    final match = RegExp(r'\d+(?:-\d+)+').firstMatch(formationName);
    if (match == null) {
      return [4, 4, 2];
    }
    return match.group(0)!.split('-').map(int.parse).toList();
  }

  /// GK(13) 포함, 포메이션에 해당하는 슬롯만 반환
  static Set<int> occupiedSlots(String formationName) {
    final lines = parseLineCounts(formationName);
    if (lines.isEmpty) {
      return {13};
    }

    final slots = <int>{13};

    if (lines.length == 3) {
      _add(slots, lines[0], const [10, 11, 12]);
      _add(slots, lines[1], const [7, 8, 9, 4, 5, 6]);
      _add(slots, lines[2], const [1, 2, 3]);
      return slots;
    }

    if (lines.length == 4) {
      _add(slots, lines[0], const [7, 10, 11, 12, 9]);
      _add(slots, lines[1], const [7, 8, 9, 4, 5, 6]);
      _add(slots, lines[2], const [4, 5, 6, 1, 2, 3]);
      _add(slots, lines[3], const [1, 2, 3]);
      return slots;
    }

    if (lines.length == 5) {
      _add(slots, lines[0], const [10, 11, 12]);
      _add(slots, lines[1], const [7, 8, 9]);
      _add(slots, lines[2], const [4, 5, 6]);
      _add(slots, lines[3], const [1, 2, 3]);
      _add(slots, lines[4], const [1, 2, 3]);
      return slots;
    }

    final bands = [
      const [10, 11, 12],
      const [7, 8, 9],
      const [4, 5, 6],
      const [1, 2, 3],
    ];
    for (var i = 0; i < lines.length; i++) {
      final bandIndex = ((i / lines.length) * bands.length).floor().clamp(0, bands.length - 1);
      _add(slots, lines[i], bands[bandIndex]);
    }
    return slots;
  }

  static void _add(Set<int> slots, int count, List<int> pool) {
    for (final slot in _pickFromPool(count, pool)) {
      slots.add(slot);
    }
  }

  static List<int> _pickFromPool(int count, List<int> pool) {
    if (count <= 0 || pool.isEmpty) {
      return [];
    }
    if (count >= pool.length) {
      return List<int>.from(pool);
    }
    if (count == 1) {
      return [pool[pool.length ~/ 2]];
    }

    final picked = <int>[];
    for (var i = 0; i < count; i++) {
      final idx = (i * (pool.length - 1) / (count - 1)).round();
      picked.add(pool[idx]);
    }
    return picked;
  }
}
