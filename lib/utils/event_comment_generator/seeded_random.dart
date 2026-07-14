/// Mulberry32 — matches match_engine SeededRandom for commentary reproducibility.
class SeededRandom {
  SeededRandom(int seed) : _state = (seed & 0xffffffff) == 0 ? 1 : (seed & 0xffffffff);

  int _state;

  double next() {
    var t = (_state = (_state + 0x6d2b79f5) & 0xffffffff);
    t = _imul(t ^ (t >> 15), t | 1);
    t ^= t + _imul(t ^ (t >> 7), t | 61);
    return ((t ^ (t >> 14)) & 0xffffffff) / 4294967296.0;
  }

  int nextInt(int max) {
    if (max <= 0) return 0;
    return (next() * max).floor();
  }

  bool boolChance(double p) => next() < p;

  T pick<T>(List<T> items) {
    if (items.isEmpty) {
      throw StateError('SeededRandom.pick: empty');
    }
    return items[nextInt(items.length)];
  }

  T weightedPick<T>(List<({T value, double w})> items) {
    var total = 0.0;
    for (final it in items) {
      if (it.w > 0) total += it.w;
    }
    if (total <= 0) return items.first.value;
    var r = next() * total;
    for (final it in items) {
      if (it.w <= 0) continue;
      r -= it.w;
      if (r <= 0) return it.value;
    }
    return items.last.value;
  }

  static int _imul(int a, int b) => (a * b) & 0xffffffff;
}

int commentarySeed({
  required int matchSeed,
  required int minute,
  required int second,
  required String type,
  String? primaryPlayerId,
}) {
  var h = 2166136261;
  void mix(int v) {
    h ^= v & 0xffffffff;
    h = _imul(h, 16777619);
  }

  void mixStr(String s) {
    for (final c in s.codeUnits) {
      mix(c);
    }
  }

  mix(matchSeed);
  mix(minute);
  mix(second);
  mixStr(type);
  mixStr(primaryPlayerId ?? '');
  return h & 0xffffffff;
}

int _imul(int a, int b) => (a * b) & 0xffffffff;
