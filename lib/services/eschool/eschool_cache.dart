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

  String get storageKey =>
      base64UrlEncode(utf8.encode(jsonEncode([kind, scope])));

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
  Future<Map<String, String>> readAll();

  Future<void> write(String key, String value);

  Future<void> remove(String key);

  Future<void> clear();
}

abstract interface class EschoolAsyncPreferences {
  Future<Set<String>> getKeys({Set<String>? allowList});

  Future<Map<String, Object?>> getAll({Set<String>? allowList});

  Future<void> setString(String key, String value);

  Future<void> remove(String key);

  Future<void> clear({Set<String>? allowList});
}

class SharedPreferencesEschoolMetadataStore implements EschoolMetadataStore {
  SharedPreferencesEschoolMetadataStore({EschoolAsyncPreferences? preferences})
      : _preferences = preferences ?? _SharedPreferencesAsyncAdapter();

  static const storagePrefix = 'eschool.metadata.v2.';

  final EschoolAsyncPreferences _preferences;

  String _preferenceKey(String recordKey) => '$storagePrefix$recordKey';

  @override
  Future<Map<String, String>> readAll() async {
    final keys = (await _preferences.getKeys())
        .where((key) => key.startsWith(storagePrefix))
        .toSet();
    if (keys.isEmpty) return const {};
    final values = await _preferences.getAll(allowList: keys);
    final invalidKeys = values.entries
        .where((entry) => entry.value is! String)
        .map((entry) => entry.key)
        .toSet();
    if (invalidKeys.isNotEmpty) {
      await _preferences.clear(allowList: invalidKeys);
    }
    return {
      for (final entry in values.entries)
        if (entry.key.startsWith(storagePrefix) && entry.value is String)
          entry.key.substring(storagePrefix.length): entry.value! as String,
    };
  }

  @override
  Future<void> write(String key, String value) =>
      _preferences.setString(_preferenceKey(key), value);

  @override
  Future<void> remove(String key) => _preferences.remove(_preferenceKey(key));

  @override
  Future<void> clear() async {
    final keys = (await _preferences.getKeys())
        .where((key) => key.startsWith(storagePrefix))
        .toSet();
    if (keys.isNotEmpty) await _preferences.clear(allowList: keys);
  }
}

class _SharedPreferencesAsyncAdapter implements EschoolAsyncPreferences {
  SharedPreferencesAsync get _preferences => SharedPreferencesAsync();

  @override
  Future<void> clear({Set<String>? allowList}) =>
      _preferences.clear(allowList: allowList);

  @override
  Future<Map<String, Object?>> getAll({Set<String>? allowList}) =>
      _preferences.getAll(allowList: allowList);

  @override
  Future<Set<String>> getKeys({Set<String>? allowList}) =>
      _preferences.getKeys(allowList: allowList);

  @override
  Future<void> remove(String key) => _preferences.remove(key);

  @override
  Future<void> setString(String key, String value) =>
      _preferences.setString(key, value);
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
      schemaVersion: schemaVersion,
      key: key,
      protocolVersion: protocolVersion,
      savedAt: now,
      expiresAt: now.add(ttl),
      value: encoded,
    );
    await _persistRecordBestEffort(key.storageKey);
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
      await _removePersistedRecordBestEffort(key);
    }
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
      final records = await _store.readAll();
      final invalidKeys = <String>[];
      for (final entry in records.entries) {
        final Object? decoded;
        try {
          decoded = jsonDecode(entry.value);
        } on Object {
          invalidKeys.add(entry.key);
          continue;
        }
        final record = _CacheRecord.tryParse(decoded);
        if (record == null ||
            record.schemaVersion != schemaVersion ||
            record.protocolVersion != protocolVersion ||
            record.key.storageKey != entry.key) {
          invalidKeys.add(entry.key);
          continue;
        }
        _records[entry.key] = record;
      }
      _loaded = true;
      for (final key in invalidKeys) {
        await _removePersistedRecordBestEffort(key);
      }
    } on Object {
      _records.clear();
      _loaded = true;
      // Treat an unavailable local metadata store as an empty cache.
    }
  }

  Future<void> _removeRecord(String storageKey) async {
    _records.remove(storageKey);
    await _removePersistedRecordBestEffort(storageKey);
  }

  Future<void> _persistRecordBestEffort(String storageKey) async {
    final record = _records[storageKey];
    if (record == null) return;
    try {
      await _store.write(storageKey, jsonEncode(record.toJson()));
    } on Object {
      // Keep the in-memory cache usable when persistence is unavailable.
    }
  }

  Future<void> _removePersistedRecordBestEffort(String storageKey) async {
    try {
      await _store.remove(storageKey);
    } on Object {
      // Keep the in-memory cache usable when persistence is unavailable.
    }
  }
}

class _CacheRecord {
  const _CacheRecord({
    required this.schemaVersion,
    required this.key,
    required this.protocolVersion,
    required this.savedAt,
    required this.expiresAt,
    required this.value,
  });

  final int schemaVersion;
  final EschoolCacheKey key;
  final String protocolVersion;
  final DateTime savedAt;
  final DateTime expiresAt;
  final Object? value;

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
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
    final schemaVersion = map['schemaVersion'];
    final kind = map['kind'];
    final scope = map['scope'];
    final protocolVersion = map['protocolVersion'];
    final savedAt = map['savedAt'];
    final expiresAt = map['expiresAt'];
    if (schemaVersion is! int ||
        kind is! String ||
        scope is! String ||
        protocolVersion is! String ||
        savedAt is! int ||
        expiresAt is! int) {
      return null;
    }
    return _CacheRecord(
      schemaVersion: schemaVersion,
      key: EschoolCacheKey(kind, scope),
      protocolVersion: protocolVersion,
      savedAt: DateTime.fromMillisecondsSinceEpoch(savedAt),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAt),
      value: map['value'],
    );
  }
}
