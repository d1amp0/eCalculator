import 'dart:convert';
import 'dart:io';

import 'package:ecalculator/services/eschool/eschool_cache.dart';
import 'package:ecalculator/services/eschool/eschool_diagnostics.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('default metadata store selection uses SQLite only on Windows', () {
    final windowsStore = _MemoryMetadataStore();
    final otherStore = _MemoryMetadataStore();

    expect(
      createDefaultEschoolMetadataStore(
        platform: EschoolMetadataStorePlatform.windows,
        windowsStoreFactory: () => windowsStore,
        otherStoreFactory: () => otherStore,
      ),
      same(windowsStore),
    );
    expect(
      createDefaultEschoolMetadataStore(
        platform: EschoolMetadataStorePlatform.other,
        windowsStoreFactory: () => windowsStore,
        otherStoreFactory: () => otherStore,
      ),
      same(otherStore),
    );
  });

  group('SqliteEschoolMetadataStore', () {
    late Directory temporaryDirectory;
    late String databasePath;
    late List<SqliteEschoolMetadataStore> stores;

    setUp(() async {
      temporaryDirectory =
          await Directory.systemTemp.createTemp('eschool-metadata-test-');
      databasePath = path.join(temporaryDirectory.path, 'metadata.db');
      stores = [];
    });

    tearDown(() async {
      for (final store in stores.reversed) {
        await store.close();
      }
      await temporaryDirectory.delete(recursive: true);
    });

    SqliteEschoolMetadataStore openStore() {
      final store = SqliteEschoolMetadataStore.forPath(databasePath);
      stores.add(store);
      return store;
    }

    test('multiple records and audit visibility survive a file reopen',
        () async {
      final first = openStore();
      await first.write('academic-years-key', 'academic-years-value');
      await first.write('classes-key', 'classes-value');
      await first.write('periods-key', 'periods-value');
      expect(await first.verifyStringRecord('classes-key'), isTrue);
      expect(await first.visibleRecordCount(), 3);
      await first.close();

      final reopened = openStore();
      expect(
        await reopened.readAll(),
        {
          'academic-years-key': 'academic-years-value',
          'classes-key': 'classes-value',
          'periods-key': 'periods-value',
        },
      );
      expect(await reopened.verifyStringRecord('academic-years-key'), isTrue);
      expect(await reopened.verifyStringRecord('missing-key'), isFalse);
      expect(await reopened.visibleRecordCount(), 3);
    });

    test('writing an existing key replaces only that record', () async {
      final first = openStore();
      await first.write('first-key', 'old-value');
      await first.write('second-key', 'stable-value');
      await first.write('first-key', 'new-value');
      await first.close();

      final reopened = openStore();
      expect(
        await reopened.readAll(),
        {'first-key': 'new-value', 'second-key': 'stable-value'},
      );
    });

    test('remove deletes only the requested key', () async {
      final first = openStore();
      await first.write('removed-key', 'removed-value');
      await first.write('retained-key', 'retained-value');
      await first.remove('removed-key');
      await first.close();

      final reopened = openStore();
      expect(
        await reopened.readAll(),
        {'retained-key': 'retained-value'},
      );
    });

    test('clear deletes every metadata record', () async {
      final first = openStore();
      await first.write('first-key', 'first-value');
      await first.write('second-key', 'second-value');
      await first.clear();
      await first.close();

      final reopened = openStore();
      expect(await reopened.readAll(), isEmpty);
      expect(await reopened.visibleRecordCount(), 0);
    });

    test('audit diagnostics expose no SQLite key, value, scope, or path',
        () async {
      final store = openStore();
      final events = <String>[];
      const cacheKey = EschoolCacheKey(
        'subjects',
        'private-account-position-organization-scope',
      );
      const privateValue = 'private-academic-metadata-value';
      final cache = EschoolMetadataCache(
        store: store,
        diagnostics: EschoolDiagnostics(enabled: true, sink: events.add),
      );

      await cache.put(
        cacheKey,
        privateValue,
        const Duration(hours: 24),
        _stringCodec,
      );

      final decodedEvents = events.map(_decodeAuditEvent).toList();
      expect(
        decodedEvents,
        contains(
          allOf(
            containsPair('event', 'cache-write'),
            containsPair('kind', 'subjects'),
            containsPair('verified', true),
          ),
        ),
      );
      expect(
        decodedEvents,
        contains(
          allOf(
            containsPair('event', 'cache-storage-summary'),
            containsPair('records', 1),
          ),
        ),
      );
      final auditText = events.join();
      expect(auditText, isNot(contains(cacheKey.scope)));
      expect(auditText, isNot(contains(cacheKey.storageKey)));
      expect(auditText, isNot(contains(privateValue)));
      expect(auditText, isNot(contains(databasePath)));
    });
  });
}

final _stringCodec = EschoolCacheCodec<String>(
  encode: (value) => value,
  decode: (value) => value! as String,
);

Map<String, dynamic> _decodeAuditEvent(String message) =>
    jsonDecode(message.substring('ESCOOL_PROTOCOL_AUDIT '.length))
        as Map<String, dynamic>;

class _MemoryMetadataStore implements EschoolMetadataStore {
  final values = <String, String>{};

  @override
  Future<void> clear() async => values.clear();

  @override
  Future<Map<String, String>> readAll() async => Map.of(values);

  @override
  Future<void> remove(String key) async => values.remove(key);

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
