import 'dart:io';

import 'package:ecalculator/other/task.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor() : _providedDatabase = null;

  DatabaseHelper.withDatabase(Database database) : _providedDatabase = database;

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  final Database? _providedDatabase;

  Future<Database> get _defaultDatabase async {
    return _database ??= await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'hw.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY,
        subject TEXT,
        info TEXT,
        time INTEGER
      )
    ''');
  }

  Future<List<Task>> getTasks() {
    final provided = _providedDatabase;
    if (provided != null) return _getTasks(provided);
    return _getTasksFromDefault();
  }

  Future<List<Task>> _getTasksFromDefault() async =>
      _getTasks(await _defaultDatabase);

  Future<List<Task>> _getTasks(Database db) async {
    var tasks = await db.query('tasks', orderBy: 'subject');
    List<Task> tasksList =
        tasks.isNotEmpty ? tasks.map((c) => Task.fromMap(c)).toList() : [];
    return tasksList;
  }

  Future<int> add(Task task) {
    final provided = _providedDatabase;
    if (provided != null) return provided.insert('tasks', task.toMap());
    return _addToDefault(task);
  }

  Future<int> _addToDefault(Task task) async {
    final db = await _defaultDatabase;
    return db.insert('tasks', task.toMap());
  }

  Future<int> removeById(int id) {
    final provided = _providedDatabase;
    if (provided != null) {
      return provided.delete('tasks', where: 'id = ?', whereArgs: [id]);
    }
    return _removeFromDefault(id);
  }

  Future<int> _removeFromDefault(int id) async {
    final db = await _defaultDatabase;
    return db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}
