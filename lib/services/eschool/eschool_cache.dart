import 'dart:async';
import 'dart:convert';

import 'package:ecalculator/services/eschool/eschool_protocol.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef EschoolClock = DateTime Function();

abstract final class EschoolCachePolicy {
  static const academicYears = Duration(days: 30);
  static const classes = Duration(days: 30);
  static const periods = Duration(days: 30);
  static const subjects = Duration(hours: 24);
  static const markDictionaries = Duration(days: 7);
}

class EschoolCacheKey {
  const EschoolCacheKey(this.kind, this.scope);

  final String kind;
  final String scope;

  String get storageKey => jsonEncode([kind, scope]);

  @override
  bool operator ==(Object other) =>
      other is EschoolCacheKey && other.kind == kind && other.scope == scope;

  @override
  int get hashCode => Object.hash(kind, scope);
}

class EschoolCacheCodec<T extends Object> {
  const EschoolCacheCodec({
    required this.encode,
    required this.decode,
  });

  final Object? Function(T value) encode;
  final T Function(Object? value) decode;
}

abstract interface class EschoolMetadataStore {
  Future<String?> read();

  Future<void> write(String value);

  Future<void> clear();
}

class SharedPreferencesEschoolMetadataStore implements EschoolMetadataStore {
  SharedPreferencesEschoolMetadataStore({SharedPreferences? preferences})
      : _preferences = preferences;

  static const storageKey = 'eschool.metadata_cache';

  final SharedPreferences? _preferences;

  Future<SharedPreferences> get _instance async =>
      _preferences ?? SharedPreferences.getInstance();

  @override
  Future<String?> read() async => (await _instance).getString(storageKey);

  @override
  Future<void> write(String value) async {
    await (await _instance).setString(storageKey, value);
  }

  @override
  Future<void> clear() async {
    await (await _instance).remove(storageKey);
  }
}

/// Memory-fronted, persistent cache for non-sensitive academic metadata.
///
/// Callers must supply a typed codec so only the approved metadata projection
/// is persisted. Raw responses, authentication material, grades, and homework
/// never pass through this cache.
class EschoolMetadataCache {
  EschoolMetadataCache({
    EschoolClock? clock,
    EschoolMetadataStore? store,
    this.schemaVersion = currentSchemaVersion,
    this.protocolVersion = EschoolProtocol.clientVersion,
  })  : _clock = clock ?? DateTime.now,
        _store = store ?? SharedPreferencesEschoolMetadataStore();

  static const currentSchemaVersion = 2;

  final EschoolClock _clock;
  final EschoolMetadataStore _store;
  final int schemaVersion;
  final String protocolVersion;
  final Map<String, _CacheRecord> _records = {};
  bool _loaded = false;
  Future<void>? _loadFuture;

  Future<T?> get<T extends Object>(
    EschoolCacheKey key,
    EschoolCacheCodec<T> codec,
  ) async {
    await _ensureLoaded();
    final record = _records[key.storageKey];
    if (record == null) return null;
    if (record.key != key ||
        record.protocolVersion != protocolVersion ||
        !_clock().isBefore(record.expiresAt)) {
      await _removeRecord(key.storageKey);
      return null;
    }
    try {
      return codec.decode(record.value);
    } on Object {
      await _removeRecord(key.storageKey);
      return null;
    }
  }

  Future<void> put<T extends Object>(
    EschoolCacheKey key,
    T value,
    Duration ttl,
    EschoolCacheCodec<T> codec,
  ) async {
    await _ensureLoaded();
    final now = _clock();
    final encoded = codec.encode(value);
    // Verify that the codec output is JSON-compatible before changing memory.
    jsonEncode(encoded);
    _records[key.storageKey] = _CacheRecord(
      key: key,
      protocolVersion: protocolVersion,
      savedAt: now,
      expiresAt: now.add(ttl),
      value: encoded,
    );
    await _persistBestEffort();
  }

  Future<T> getOrLoad<T extends Object>(
    EschoolCacheKey key,
    Duration ttl,
    EschoolCacheCodec<T> codec,
    Future<T> Function() loader,
  ) async {
    final cached = await get(key, codec);
    if (cached != null) return cached;
    final loaded = await loader();
    try {
      await put(key, loaded, ttl, codec);
    } on Object {
      // Persistence is an optimization. Fresh network data remains usable if
      // the local metadata store is unavailable.
    }
    return loaded;
  }

  Future<void> invalidate(EschoolCacheKey key) async {
    await _ensureLoaded();
    await _removeRecord(key.storageKey);
  }

  Future<void> invalidateWhere(
    bool Function(EschoolCacheKey key) predicate,
  ) async {
    await _ensureLoaded();
    final keys = _records.entries
        .where((entry) => predicate(entry.value.key))
        .map((entry) => entry.key)
        .toList(growable: false);
    if (keys.isEmpty) return;
    for (final key in keys) {
      _records.remove(key);
    }
    await _persistBestEffort();
  }

  Future<void> clear() async {
    final pendingLoad = _loadFuture;
    if (pendingLoad != null) {
      try {
        await pendingLoad;
      } on Object {
        // Clearing must still proceed if the initial read failed.
      }
    }
    _records.clear();
    _loaded = true;
    _loadFuture = null;
    try {
      await _store.clear();
    } on Object {
      // An unavailable metadata store must not affect logout/session safety.
    }
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final pending = _loadFuture ??= _load();
    await pending;
  }

  Future<void> _load() async {
    try {
      final raw = await _store.read();
      if (raw == null) {
        _loaded = true;
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map ||
          decoded['schemaVersion'] != schemaVersion ||
          decoded['records'] is! Map) {
        await _discardPersistedData();
        return;
      }
      final records = Map<Object?, Object?>.from(decoded['records'] as Map);
      for (final entry in records.entries) {
        if (entry.key is! String) continue;
        final record = _CacheRecord.tryParse(entry.value);
        if (record == null || record.protocolVersion != protocolVersion) {
          continue;
        }
        _records[entry.key as String] = record;
      }
      _loaded = true;
      // Rewrite after load to remove corrupt or obsolete individual records.
      if (_records.length != records.length) await _persistBestEffort();
    } on Object {
      await _discardPersistedData();
    }
  }

  Future<void> _discardPersistedData() async {
    _records.clear();
    _loaded = true;
    try {
      await _store.clear();
    } on Object {
      // Treat unreadable local metadata as an empty cache.
    }
  }

  Future<void> _removeRecord(String storageKey) async {
    if (_records.remove(storageKey) != null) await _persistBestEffort();
  }

  Future<void> _persistBestEffort() async {
    final payload = jsonEncode({
      'schemaVersion': schemaVersion,
      'records': {
        for (final entry in _records.entries) entry.key: entry.value.toJson(),
      },
    });
    try {
      await _store.write(payload);
    } on Object {
      // Keep the in-memory cache usable when persistence is unavailable.
    }
  }
}

class _CacheRecord {
  const _CacheRecord({
    required this.key,
    required this.protocolVersion,
    required this.savedAt,
    required this.expiresAt,
    required this.value,
  });

  final EschoolCacheKey key;
  final String protocolVersion;
  final DateTime savedAt;
  final DateTime expiresAt;
  final Object? value;

  Map<String, Object?> toJson() => {
        'kind': key.kind,
        'scope': key.scope,
        'protocolVersion': protocolVersion,
        'savedAt': savedAt.millisecondsSinceEpoch,
        'expiresAt': expiresAt.millisecondsSinceEpoch,
        'value': value,
      };

  static _CacheRecord? tryParse(Object? value) {
    if (value is! Map) return null;
    final map = Map<Object?, Object?>.from(value);
    final kind = map['kind'];
    final scope = map['scope'];
    final protocolVersion = map['protocolVersion'];
    final savedAt = map['savedAt'];
    final expiresAt = map['expiresAt'];
    if (kind is! String ||
        scope is! String ||
        protocolVersion is! String ||
        savedAt is! int ||
        expiresAt is! int) {
      return null;
    }
    return _CacheRecord(
      key: EschoolCacheKey(kind, scope),
      protocolVersion: protocolVersion,
      savedAt: DateTime.fromMillisecondsSinceEpoch(savedAt),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAt),
      value: map['value'],
    );
  }
}
