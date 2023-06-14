import 'package:flutter_pasteboard/pasteboard_item.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = "flutter_pasteboard.db";
  static const _databaseVersion = 1;

  // 私有构造函数
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  factory DatabaseHelper() => instance;

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // await db.execute('DROP TABLE IF EXISTS $table');
    await db.execute(createPasteboardItem);
  }

  Future<PasteboardItem> insert(PasteboardItem item) async {
    Database db = await instance.database;
    int id = await db.insert(table, item.toMap());
    item.id = id;
    return item;
  }

  Future<int> update(PasteboardItem item) async {
    Database db = await instance.database;
    return await db.update(
      table,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<List<PasteboardItem>> queryAll() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> map = await db.query(
      table,
      orderBy: 'create_time DESC',
    );
    return map.map((e) => PasteboardItem.fromMap(e)).toList();
  }
}

String createPasteboardItem = '''
  CREATE TABLE IF NOT EXISTS $table (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type INTEGER NOT NULL,
    text TEXT,
    image BLOB,
    sha256 TEXT UNIQUE NOT NULL,
    create_time INTEGER NOT NULL
  )
''';
const table = 'pasteboard_item';
