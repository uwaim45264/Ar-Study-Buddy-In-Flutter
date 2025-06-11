import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';


class NoteDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'notes.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE notes(id INTEGER PRIMARY KEY, text TEXT, timestamp TEXT)');
      },
    );
  }

  static Future<void> saveNote(String text) async {
    final db = await database;
    print('NoteDatabase: Saving note, length: ${text.length}'); // Debug log
    await db.insert(
      'notes',
      {
        'text': text,
        'timestamp': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('NoteDatabase: Note saved successfully'); // Debug log
  }

  static Future<List<String>> getNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('notes');
    final notes = List.generate(maps.length, (i) {
      final text = maps[i]['text'] as String;
      print('NoteDatabase: Retrieved note, length: ${text.length}'); // Debug log
      return text;
    });
    return notes;
  }
}