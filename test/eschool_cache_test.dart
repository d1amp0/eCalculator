import 'dart:async';

import 'package:ecalculator/services/eschool/eschool_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('persistent metadata cache', () {
    test('survives a new cache instance and reuses an unexpired value',
        () async {
      final store = _MemoryMetadataStore();
      var loads = 0;
      final first = EschoolMetadataCache(store: store);
      expect(
        await first.getOrLoad(
          _accountA,
          const Duration(days: 30),
          _stringCodec,
          () async => 'value-${++loads}',
        ),
        'value-1',
      );

      final afterRestart = EschoolMetadataCache(store: store);
      expect(
        await afterRestart.getOrLoad(
          _accountA,
          const Duration(days: 30),
          _stringCodec,
          () async => 'value-${++loads}',
        ),
        'value-1',
      );
      expect(loads, 1);
    });

    test('SharedPreferencesAsync backing survives a new cache instance',
        () async {
      final preferences = _MemoryAsyncPreferences();
      final store = SharedPreferencesEschoolMetadataStore(
        preferences: preferences,
      );
      final first = EschoolMetadataCache(store: store);
      await first.put(
        _accountA,
        'persisted',
        const Duration(days: 30),
        _stringCodec,
      );

      final afterRestart = EschoolMetadataCache(
        store: SharedPreferencesEschoolMetadataStore(
          preferences: preferences,
        ),
      );
      expect(await afterRestart.get(_accountA, _stringCodec), 'persisted');
      final recordKey = preferences.values.keys.singleWhere(
        (key) => key.startsWith(
          SharedPreferencesEschoolMetadataStore.storagePrefix,
        ),
      );
      expect(
        preferences.values[recordKey],
        contains('expiresAt'),
      );
    });

    test('expired value is removed and reloaded', () async {
      var now = DateTime(2026, 8, 30, 12);
      final store = _MemoryMetadataStore();
      var loads = 0;
      final first = EschoolMetadataCache(store: store, clock: () => now);
      await first.getOrLoad(
        _accountA,
        const Duration(hours: 1),
        _stringCodec,
        () async => 'value-${++loads}',
      );

      now = now.add(const Duration(hours: 1));
      final afterExpiry = EschoolMetadataCache(store: store, clock: () => now);
      expect(
        await afterExpiry.getOrLoad(
          _accountA,
          const Duration(hours: 1),
          _stringCodec,
          () async => 'value-${++loads}',
        ),
        'value-2',
      );
    });

    test('corrupted persisted data is ignored safely', () async {
      final store = _MemoryMetadataStore()
        ..values[_accountA.storageKey] = '{not-json';
      var loads = 0;
      final cache = EschoolMetadataCache(store: store);

      expect(
        await cache.getOrLoad(
          _accountA,
          const Duration(days: 30),
          _stringCodec,
          () async => 'fresh-${++loads}',
        ),
        'fresh-1',
      );
      expect(loads, 1);
    });

    test('cache schema mismatch reloads', () async {
      final store = _MemoryMetadataStore();
      await EschoolMetadataCache(store: store, schemaVersion: 2).put(
        _accountA,
        'old',
        const Duration(days: 30),
        _stringCodec,
      );
      var loads = 0;
      final upgraded = EschoolMetadataCache(store: store, schemaVersion: 3);

      expect(
        await upgraded.getOrLoad(
          _accountA,
          const Duration(days: 30),
          _stringCodec,
          () async => 'new-${++loads}',
        ),
        'new-1',
      );
    });

    test('protocol version mismatch reloads', () async {
      final store = _MemoryMetadataStore();
      await EschoolMetadataCache(store: store, protocolVersion: 'v.4207').put(
        _accountA,
        'old',
        const Duration(days: 30),
        _stringCodec,
      );
      var loads = 0;
      final upgraded = EschoolMetadataCache(
        store: store,
        protocolVersion: 'v.4208',
      );

      expect(
        await upgraded.getOrLoad(
          _accountA,
          const Duration(days: 30),
          _stringCodec,
          () async => 'new-${++loads}',
        ),
        'new-1',
      );
    });

    test('account scopes never leak into each other', () async {
      final store = _MemoryMetadataStore();
      final cache = EschoolMetadataCache(store: store);
      await cache.put(
        _accountA,
        'account-a',
        const Duration(days: 30),
        _stringCodec,
      );

      expect(await cache.get(_accountA, _stringCodec), 'account-a');
      expect(await cache.get(_accountB, _stringCodec), isNull);
    });

    test('manual invalidation removes memory and persistent values', () async {
      final store = _MemoryMetadataStore();
      final cache = EschoolMetadataCache(store: store);
      await cache.put(
        _accountA,
        'cached',
        const Duration(days: 30),
        _stringCodec,
      );
      await cache.invalidate(_accountA);

      expect(await cache.get(_accountA, _stringCodec), isNull);
      final afterRestart = EschoolMetadataCache(store: store);
      expect(await afterRestart.get(_accountA, _stringCodec), isNull);
    });

    test('two loaded cache instances preserve writes to different keys',
        () async {
      final preferences = _MemoryAsyncPreferences();
      final foreground = EschoolMetadataCache(
        store: SharedPreferencesEschoolMetadataStore(
          preferences: preferences,
        ),
      );
      final background = EschoolMetadataCache(
        store: SharedPreferencesEschoolMetadataStore(
          preferences: preferences,
        ),
      );
      expect(await foreground.get(_accountA, _stringCodec), isNull);
      expect(await background.get(_accountB, _stringCodec), isNull);

      await foreground.put(
        _accountA,
        'foreground',
        const Duration(days: 30),
        _stringCodec,
      );
      await background.put(
        _accountB,
        'background',
        const Duration(days: 30),
        _stringCodec,
      );

      final fresh = EschoolMetadataCache(
        store: SharedPreferencesEschoolMetadataStore(
          preferences: preferences,
        ),
      );
      expect(await fresh.get(_accountA, _stringCodec), 'foreground');
      expect(await fresh.get(_accountB, _stringCodec), 'background');
    });

    test('invalidating one key preserves records written by another instance',
        () async {
      final preferences = _MemoryAsyncPreferences();
      EschoolMetadataCache cache() => EschoolMetadataCache(
            store: SharedPreferencesEschoolMetadataStore(
              preferences: preferences,
            ),
          );
      await cache().put(
        _accountA,
        'account-a',
        const Duration(days: 30),
        _stringCodec,
      );
      await cache().put(
        _accountB,
        'account-b',
        const Duration(days: 30),
        _stringCodec,
      );

      await cache().invalidate(_accountA);

      final fresh = cache();
      expect(await fresh.get(_accountA, _stringCodec), isNull);
      expect(await fresh.get(_accountB, _stringCodec), 'account-b');
    });

    test('clear removes only prefixed eSchool metadata preferences', () async {
      final preferences = _MemoryAsyncPreferences()
        ..values['unrelated.application.setting'] = 'keep';
      final cache = EschoolMetadataCache(
        store: SharedPreferencesEschoolMetadataStore(
          preferences: preferences,
        ),
      );
      await cache.put(
        _accountA,
        'account-a',
        const Duration(days: 30),
        _stringCodec,
      );
      await cache.put(
        _accountB,
        'account-b',
        const Duration(days: 30),
        _stringCodec,
      );

      await cache.clear();

      expect(preferences.values, {'unrelated.application.setting': 'keep'});
    });

    test('clear cannot be undone by an in-flight persistent read', () async {
      final seeded = _MemoryMetadataStore();
      await EschoolMetadataCache(store: seeded).put(
        _accountA,
        'stale-session',
        const Duration(days: 30),
        _stringCodec,
      );
      final store = _DelayedReadMetadataStore(seeded.values);
      final cache = EschoolMetadataCache(store: store);
      final read = cache.get(_accountA, _stringCodec);
      final clear = cache.clear();

      store.releaseRead();
      await read;
      await clear;

      expect(await cache.get(_accountA, _stringCodec), isNull);
      expect(store.values, isEmpty);
    });
  });

  test('metadata TTL policies match stability boundaries', () {
    expect(EschoolCachePolicy.academicYears, const Duration(days: 30));
    expect(EschoolCachePolicy.classes, const Duration(days: 30));
    expect(EschoolCachePolicy.periods, const Duration(days: 30));
    expect(EschoolCachePolicy.subjects, const Duration(hours: 24));
    expect(EschoolCachePolicy.markDictionaries, const Duration(days: 7));
  });
}

const _accountA = EschoolCacheKey('subjects', 'account-a|class-1|period-1');
const _accountB = EschoolCacheKey('subjects', 'account-b|class-1|period-1');

final _stringCodec = EschoolCacheCodec<String>(
  encode: (value) => value,
  decode: (value) {
    if (value is! String) throw const FormatException('Expected string');
    return value;
  },
);

class _MemoryMetadataStore implements EschoolMetadataStore {
  _MemoryMetadataStore([Map<String, String>? initialValues])
      : values = Map.of(initialValues ?? const {});

  final Map<String, String> values;

  @override
  Future<void> clear() async => values.clear();

  @override
  Future<Map<String, String>> readAll() async => Map.of(values);

  @override
  Future<void> remove(String key) async => values.remove(key);

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class _DelayedReadMetadataStore extends _MemoryMetadataStore {
  _DelayedReadMetadataStore(super.initialValues);

  final _readGate = Completer<void>();

  void releaseRead() => _readGate.complete();

  @override
  Future<Map<String, String>> readAll() async {
    await _readGate.future;
    return super.readAll();
  }
}

class _MemoryAsyncPreferences implements EschoolAsyncPreferences {
  final Map<String, Object?> values = {};

  @override
  Future<void> clear({Set<String>? allowList}) async {
    if (allowList == null) {
      values.clear();
      return;
    }
    values.removeWhere((key, _) => allowList.contains(key));
  }

  @override
  Future<Map<String, Object?>> getAll({Set<String>? allowList}) async => {
        for (final entry in values.entries)
          if (allowList == null || allowList.contains(entry.key))
            entry.key: entry.value,
      };

  @override
  Future<Set<String>> getKeys({Set<String>? allowList}) async => values.keys
      .where((key) => allowList == null || allowList.contains(key))
      .toSet();

  @override
  Future<void> remove(String key) async => values.remove(key);

  @override
  Future<void> setString(String key, String value) async => values[key] = value;
}
