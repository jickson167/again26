String? _normalize(String? s) {
  if (s == null) return null;
  return s.trim().toLowerCase();
}

String? _countryCodeFromName(String? name) {
  final n = _normalize(name);
  if (n == null) return null;

  const map = {
    '대한민국': 'KR',
    '한국': 'KR',
    '일본': 'JP',
    '미국': 'US',
    '영국': 'GB',
    '잉글랜드': 'GB',
    '스페인': 'ES',
    '포르투갈': 'PT',
    '브라질': 'BR',
    '프랑스': 'FR',
    '독일': 'DE',
    '이탈리아': 'IT',
    '아르헨티나': 'AR',
    '네덜란드': 'NL',
    '대한': 'KR',
  };

  // direct match
  for (final k in map.keys) {
    if (n == k) return map[k];
  }

  // try startsWith for variants
  for (final k in map.keys) {
    if (n.startsWith(k)) return map[k];
  }

  return null;
}

String? emojiFlagFromCountryName(String? name) {
  final code = _countryCodeFromName(name);
  if (code == null) return null;
  final up = code.toUpperCase();
  if (up.length != 2) return null;
  final runes = up.runes.map((r) => 0x1F1E6 + (r - 65)).toList();
  return String.fromCharCodes(runes);
}

// Simple helper: return emoji or fallback null
String? flagEmoji(String? countryName) => emojiFlagFromCountryName(countryName);
