import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/nation_flag_entry.dart';
import '../utils/nation_flag_paths.dart';
import '../utils/nation_flag_loader.dart';

class NationFlagService {
  NationFlagService._();

  static final NationFlagService instance = NationFlagService._();

  NationFlagMap? _map;
  Future<void>? _loading;

  Future<void> ensureLoaded() {
    return _loading ??= _load();
  }

  bool get isLoaded => _map != null;

  Future<void> _load() async {
    try {
      final raw = await loadNationFlagMapJson(nationFlagMapDataUrl());
      _map = NationFlagMap.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (error) {
      debugPrint('NationFlagService load failed: $error');
      _map = const NationFlagMap(
        entries: [],
        lookup: NationFlagLookup(byNameKo: {}, byAlias: {}),
      );
    }
  }

  ResolvedNation resolve(String? nationality) {
    final raw = nationality?.trim() ?? '';
    if (raw.isEmpty) {
      return ResolvedNation.empty;
    }

    final map = _map;
    if (map == null) {
      return ResolvedNation(displayName: raw);
    }

    final flagId = map.lookup.byAlias[raw] ?? map.lookup.byNameKo[raw];
    if (flagId == null) {
      return ResolvedNation(displayName: raw);
    }

    final entry = map.byFlagId[flagId];
    if (entry == null || entry.nameKo.isEmpty) {
      return ResolvedNation(displayName: raw);
    }

    return ResolvedNation(
      displayName: entry.nameKo,
      flagUrl: nationFlagImageUrl(entry.file),
    );
  }
}
