import 'dart:async';
import 'dart:convert';

import 'package:ecalculator/services/eschool/eschool_diagnostics.dart';
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

/// Optional audit-only visibility checks for a persistent metadata store.
/// Implementations must never return keys or values to the diagnostic layer.
abstract interface class EschoolMetadataAuditStore {
  Future<bool> verifyStringRecord(String key);

  Future<int> visibleRecordCount();
}

abstract interface class EschoolAsyncPreferences {
  Future<Set<String>> getKeys({Set<String>? allowList});

  Future<Map<String, Object?>> getAll({Set<String>? allowList});

  Future<void> setString(String key, String value);

  Future<void> remove(String key);

  Future<void> clear({Set<String>? allowList});
}

class SharedPreferencesEschoolMetadataStore
    implements EschoolMetadataStore, EschoolMetadataAuditStore {
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
    return {
      for (final entry in values.entries)
        if (entry.key.startsWith(storagePrefix))
          entry.key.substring(storagePrefix.length):
              entry.value is String ? entry.value! as String : '',
    };
  }

  @override
  Future<void> write(String key, String value) =>
      _preferences.setString(_preferenceKey(key), value);

  @override
  Future<bool> verifyStringRecord(String key) async {
    final preferenceKey = _preferenceKey(key);
    final values = await _preferences.getAll(allowList: {preferenceKey});
    return values.containsKey(preferenceKey) && values[preferenceKey] is String;
  }

  @override
  Future<int> visibleRecordCount() async {
    final keys = await _preferences.getKeys();
    return keys.where((key) => key.startsWith(storagePrefix)).length;
  }

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
    EschoolDiagnostics? diagnostics,
    this.schemaVersion = currentSchemaVersion,
    this.protocolVersion = EschoolProtocol.clientVersion,
  })  : _clock = clock ?? DateTime.now,
        _store = store ?? SharedPreferencesEschoolMetadataStore(),
        _diagnostics = diagnostics ?? EschoolDiagnostics.fromEnvironment();

  static const currentSchemaVersion = 2;

  final EschoolClock _clock;
  final EschoolMetadataStore _store;
  final EschoolDiagnostics _diagnostics;
  final int schemaVersion;
  final String protocolVersion;
  final Map<String, _CacheRecord> _records = {};
  final Map<String, String> _rejectedReasons = {};
  bool _loaded = false;
  Future<void>? _loadFuture;
  String? _storageReadFailure;

  Future<T?> get<T extends Object>(
    EschoolCacheKey key,
    EschoolCacheCodec<T> codec,
  ) async {
    await _ensureLoaded();
    final storageKey = key.storageKey;
    final record = _records[storageKey];
    if (record == null) {
      _cacheMiss(
        key,
        _rejectedReasons.remove(storageKey) ??
            _storageReadFailure ??
            'not-found',
      );
      return null;
    }
    if (record.key != key) {
      _cacheMiss(key, 'key-mismatch');
      await _removeRecord(storageKey, kind: key.kind);
      return null;
    }
    if (record.schemaVersion != schemaVersion) {
      _cacheMiss(key, 'schema-mismatch');
      await _removeRecord(storageKey, kind: key.kind);
      return null;
    }
    if (record.protocolVersion != protocolVersion) {
      _cacheMiss(key, 'protocol-mismatch');
      await _removeRecord(storageKey, kind: key.kind);
      return null;
    }
    if (!_clock().isBefore(record.expiresAt)) {
      _cacheMiss(key, 'expired');
      await _removeRecord(storageKey, kind: key.kind);
      return null;
    }
    try {
      final decoded = codec.decode(record.value);
      _diagnostics.cacheEvent(event: 'cache-hit', kind: key.kind);
      return decoded;
    } on Object {
      _cacheMiss(key, 'decode-failed');
      await _removeRecord(storageKey, kind: key.kind);
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
    _diagnostics.cacheEvent(
      event: 'cache-invalidated',
      kind: key.kind,
      reason: 'explicitly-invalidated',
    );
    await _removeRecord(key.storageKey, kind: key.kind);
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
      final record = _records.remove(key);
      if (record != null) {
        _diagnostics.cacheEvent(
          event: 'cache-invalidated',
          kind: record.key.kind,
          reason: 'explicitly-invalidated',
        );
      }
      await _removePersistedRecordBestEffort(key, kind: record?.key.kind);
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
    final recordCount = _records.length;
    _records.clear();
    _rejectedReasons.clear();
    _storageReadFailure = null;
    _loaded = true;
    _loadFuture = null;
    _diagnostics.cacheEvent(
      event: 'cache-cleared',
      reason: 'cleared',
      records: recordCount,
    );
    try {
      await _store.clear();
    } on Object {
      _diagnostics.cacheEvent(
        event: 'cache-storage-failure',
        reason: 'storage-clear-failed',
      );
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
      var accepted = 0;
      for (final entry in records.entries) {
        final Object? decoded;
        try {
          decoded = jsonDecode(entry.value);
        } on Object {
          invalidKeys.add(entry.key);
          _rejectedReasons[entry.key] = 'decode-failed';
          continue;
        }
        final record = _CacheRecord.tryParse(decoded);
        final rejectionReason = record == null
            ? 'decode-failed'
            : record.schemaVersion != schemaVersion
                ? 'schema-mismatch'
                : record.protocolVersion != protocolVersion
                    ? 'protocol-mismatch'
                    : record.key.storageKey != entry.key
                        ? 'key-mismatch'
                        : null;
        if (rejectionReason != null) {
          invalidKeys.add(entry.key);
          _rejectedReasons[entry.key] = rejectionReason;
          continue;
        }
        _records[entry.key] = record!;
        accepted++;
      }
      _loaded = true;
      _diagnostics.cacheEvent(
        event: 'cache-init',
        discovered: records.length,
        accepted: accepted,
        rejected: records.length - accepted,
      );
      for (final key in invalidKeys) {
        await _removePersistedRecordBestEffort(key);
      }
    } on Object {
      _records.clear();
      _rejectedReasons.clear();
      _storageReadFailure = 'storage-read-failed';
      _loaded = true;
      _diagnostics.cacheEvent(
        event: 'cache-init',
        reason: 'storage-read-failed',
      );
      _diagnostics.cacheEvent(
        event: 'cache-storage-failure',
        reason: 'storage-read-failed',
      );
      // Treat an unavailable local metadata store as an empty cache.
    }
  }

  void _cacheMiss(EschoolCacheKey key, String reason) {
    _diagnostics.cacheEvent(
      event: 'cache-miss',
      kind: key.kind,
      reason: reason,
    );
  }

  Future<void> _removeRecord(String storageKey, {String? kind}) async {
    _records.remove(storageKey);
    await _removePersistedRecordBestEffort(storageKey, kind: kind);
  }

  Future<void> _persistRecordBestEffort(String storageKey) async {
    final record = _records[storageKey];
    if (record == null) return;
    try {
      await _store.write(storageKey, jsonEncode(record.toJson()));
      if (_diagnostics.enabled) {
        final store = _store;
        if (store is EschoolMetadataAuditStore) {
          await _auditSuccessfulWrite(
            store as EschoolMetadataAuditStore,
            storageKey: storageKey,
            kind: record.key.kind,
          );
        }
      }
    } on Object {
      _diagnostics.cacheEvent(
        event: 'cache-storage-failure',
        kind: record.key.kind,
        reason: 'storage-write-failed',
      );
      // Keep the in-memory cache usable when persistence is unavailable.
    }
  }

  Future<void> _auditSuccessfulWrite(
    EschoolMetadataAuditStore auditStore, {
    required String storageKey,
    required String kind,
  }) async {
    final bool verified;
    try {
      verified = await auditStore.verifyStringRecord(storageKey);
    } on Object {
      _diagnostics.cacheEvent(
        event: 'cache-storage-failure',
        kind: kind,
        reason: 'storage-read-failed',
      );
      return;
    }
    _diagnostics.cacheEvent(
      event: 'cache-write',
      kind: kind,
      verified: verified,
    );

    try {
      final records = await auditStore.visibleRecordCount();
      _diagnostics.cacheEvent(
        event: 'cache-storage-summary',
        records: records,
      );
    } on Object {
      _diagnostics.cacheEvent(
        event: 'cache-storage-failure',
        kind: kind,
        reason: 'storage-read-failed',
      );
    }
  }

  Future<void> _removePersistedRecordBestEffort(
    String storageKey, {
    String? kind,
  }) async {
    try {
      await _store.remove(storageKey);
    } on Object {
      _diagnostics.cacheEvent(
        event: 'cache-storage-failure',
        kind: kind,
        reason: 'storage-remove-failed',
      );
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
