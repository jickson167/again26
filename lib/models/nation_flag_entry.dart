class NationFlagEntry {
  const NationFlagEntry({
    required this.flagId,
    required this.file,
    required this.nameKo,
    required this.nameEn,
    required this.aliases,
  });

  final String flagId;
  final String file;
  final String nameKo;
  final String nameEn;
  final List<String> aliases;

  factory NationFlagEntry.fromJson(Map<String, dynamic> json) {
    return NationFlagEntry(
      flagId: json['flag_id'] as String,
      file: json['file'] as String,
      nameKo: json['name_ko'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      aliases: (json['aliases'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
    );
  }
}

class NationFlagLookup {
  const NationFlagLookup({
    required this.byNameKo,
    required this.byAlias,
  });

  final Map<String, String> byNameKo;
  final Map<String, String> byAlias;

  factory NationFlagLookup.fromJson(Map<String, dynamic> json) {
    Map<String, String> readMap(String key) {
      final raw = json[key] as Map<String, dynamic>? ?? const {};
      return {for (final entry in raw.entries) entry.key: entry.value.toString()};
    }

    return NationFlagLookup(
      byNameKo: readMap('by_name_ko'),
      byAlias: readMap('by_alias'),
    );
  }
}

class NationFlagMap {
  const NationFlagMap({
    required this.entries,
    required this.lookup,
  });

  final List<NationFlagEntry> entries;
  final NationFlagLookup lookup;

  Map<String, NationFlagEntry> get byFlagId {
    return {for (final entry in entries) entry.flagId: entry};
  }

  factory NationFlagMap.fromJson(Map<String, dynamic> json) {
    final flags = (json['flags'] as List<dynamic>? ?? const [])
        .map((item) => NationFlagEntry.fromJson(item as Map<String, dynamic>))
        .toList();

    return NationFlagMap(
      entries: flags,
      lookup: NationFlagLookup.fromJson(
        json['lookup'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class ResolvedNation {
  const ResolvedNation({
    required this.displayName,
    this.flagUrl,
  });

  final String displayName;
  final String? flagUrl;

  static const empty = ResolvedNation(displayName: '');
}
