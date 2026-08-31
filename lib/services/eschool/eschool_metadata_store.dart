import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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

/// Durable storage for the approved, versioned eSchool academic metadata
/// records produced by [EschoolMetadataCache]. Authentication material, raw
/// responses, grades, and homework must never be passed to this store.
class SqliteEschoolMetadataStore
    implements EschoolMetadataStore, EschoolMetadataAuditStore {
  SqliteEschoolMetadataStore._(this._openDatabase);

  factory SqliteEschoolMetadataStore.forPath(String databasePath) =>
      SqliteEschoolMetadataStore._(
        () => _openSqliteMetadataDatabase(databasePath),
      );

  factory SqliteEschoolMetadataStore.windowsDefault() =>
      SqliteEschoolMetadataStore._(() async {
        final directory = await getApplicationSupportDirectory();
        return _openSqliteMetadataDatabase(
          path.join(directory.path, 'eschool_metadata.db'),
        );
      });

  static const tableName = 'metadata_records';

  final Future<Database> Function() _openDatabase;
  Future<Database>? _databaseFuture;

  Future<Database> get _database => _databaseFuture ??= _openDatabase();

  @override
  Future<Map<String, String>> readAll() async {
    final rows = await (await _database).query(
      tableName,
      columns: const ['key', 'value'],
    );
    return {
      for (final row in rows) row['key']! as String: row['value']! as String,
    };
  }

  @override
  Future<void> write(String key, String value) async {
    await (await _database).insert(
      tableName,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> remove(String key) async {
    await (await _database).delete(
      tableName,
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  @override
  Future<void> clear() async {
    await (await _database).delete(tableName);
  }

  @override
  Future<bool> verifyStringRecord(String key) async {
    final rows = await (await _database).query(
      tableName,
      columns: const ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.length == 1 && rows.single['value'] is String;
  }

  @override
  Future<int> visibleRecordCount() async {
    final rows = await (await _database).rawQuery(
      'SELECT COUNT(*) FROM $tableName',
    );
    final value = rows.single.values.single;
    return value is int ? value : 0;
  }

  Future<void> close() async {
    final pendingDatabase = _databaseFuture;
    _databaseFuture = null;
    if (pendingDatabase != null) await (await pendingDatabase).close();
  }
}

enum EschoolMetadataStorePlatform { windows, other }

EschoolMetadataStore createDefaultEschoolMetadataStore({
  EschoolMetadataStorePlatform? platform,
  EschoolMetadataStore Function()? windowsStoreFactory,
  EschoolMetadataStore Function()? otherStoreFactory,
}) {
  final selectedPlatform = platform ??
      (Platform.isWindows
          ? EschoolMetadataStorePlatform.windows
          : EschoolMetadataStorePlatform.other);
  return switch (selectedPlatform) {
    EschoolMetadataStorePlatform.windows =>
      (windowsStoreFactory ?? SqliteEschoolMetadataStore.windowsDefault)(),
    EschoolMetadataStorePlatform.other =>
      (otherStoreFactory ?? SharedPreferencesEschoolMetadataStore.new)(),
  };
}

DatabaseFactory? _desktopDatabaseFactory;

DatabaseFactory get _initializedDesktopDatabaseFactory {
  final existing = _desktopDatabaseFactory;
  if (existing != null) return existing;
  sqfliteFfiInit();
  return _desktopDatabaseFactory = databaseFactoryFfi;
}

Future<Database> _openSqliteMetadataDatabase(String databasePath) async {
  await Directory(path.dirname(databasePath)).create(recursive: true);
  return _initializedDesktopDatabaseFactory.openDatabase(
    databasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (database, _) => database.execute('''
        CREATE TABLE ${SqliteEschoolMetadataStore.tableName}(
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      '''),
    ),
  );
}
