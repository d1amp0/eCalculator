import 'package:ecalculator/other/database_helper.dart';
import 'package:ecalculator/other/task.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('removeById preserves a duplicate-text SQLite row', () async {
    sqfliteFfiInit();
    final database =
        await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(database.close);
    await database.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY,
        subject TEXT,
        info TEXT,
        time INTEGER
      )
    ''');
    final helper = DatabaseHelper.withDatabase(database);
    await helper.add(
      Task(id: 1, subject: 'Algebra', info: 'Read §12', time: 1),
    );
    await helper.add(
      Task(id: 2, subject: 'Physics', info: 'Read §12', time: 2),
    );

    expect(await helper.removeById(1), 1);

    final remaining = await helper.getTasks();
    expect(remaining, hasLength(1));
    expect(remaining.single.id, 2);
    expect(remaining.single.info, 'Read §12');
  });
}
