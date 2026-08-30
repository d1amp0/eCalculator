import 'dart:async';

import 'package:ecalculator/services/eschool/eschool_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    test('SharedPreferences backing survives a new cache instance', () async {
      SharedPreferences.setMockInitialValues({});
      final first = EschoolMetadataCache();
      await first.put(
        _accountA,
        'persisted',
        const Duration(days: 30),
        _stringCodec,
      );

      final afterRestart = EschoolMetadataCache();
      expect(await afterRestart.get(_accountA, _stringCodec), 'persisted');
      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString(
          SharedPreferencesEschoolMetadataStore.storageKey,
        ),
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
      final store = _MemoryMetadataStore()..value = '{not-json';
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

    test('clear cannot be undone by an in-flight persistent read', () async {
      final seeded = _MemoryMetadataStore();
      await EschoolMetadataCache(store: seeded).put(
        _accountA,
        'stale-session',
        const Duration(days: 30),
        _stringCodec,
      );
      final store = _DelayedReadMetadataStore(seeded.value);
      final cache = EschoolMetadataCache(store: store);
      final read = cache.get(_accountA, _stringCodec);
      final clear = cache.clear();

      store.releaseRead();
      await read;
      await clear;

      expect(await cache.get(_accountA, _stringCodec), isNull);
      expect(store.value, isNull);
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
  String? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}

class _DelayedReadMetadataStore extends _MemoryMetadataStore {
  _DelayedReadMetadataStore(String? initialValue) {
    value = initialValue;
  }

  final _readGate = Completer<void>();

  void releaseRead() => _readGate.complete();

  @override
  Future<String?> read() async {
    await _readGate.future;
    return value;
  }
}
