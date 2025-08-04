import 'dart:io';

import 'package:hello/other/task.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'hw.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
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

  Future<List<Task>> getTasks() async {
    Database db = await instance.database;
    var tasks = await db.query('tasks', orderBy: 'subject');
    List<Task> tasksList = tasks.isNotEmpty ? tasks.map((c) => Task.fromMap(c))
        .toList() : [];
    return tasksList;
  }

  Future<int> add(Task task) async {
    Database db = await instance.database;
    return await db.insert('tasks', task.toMap());
  }

  Future<int> remove(String info) async {
    Database db = await instance.database;
    return await db.delete('tasks', where: 'info = ?', whereArgs: [info]);
  }
}