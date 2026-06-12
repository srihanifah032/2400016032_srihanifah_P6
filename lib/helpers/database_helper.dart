import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/laporan.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'pelaporan.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE laporan (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        judul      TEXT NOT NULL,
        deskripsi  TEXT NOT NULL,
        latitude   REAL NOT NULL,
        longitude  REAL NOT NULL,
        foto_path  TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertLaporan(Laporan laporan) async {
    final db = await database;
    return await db.insert('laporan', laporan.toMap());
  }

  Future<List<Laporan>> getAllLaporan() async {
    final db = await database;
    final maps = await db.query('laporan', orderBy: 'id DESC');
    return maps.map((m) => Laporan.fromMap(m)).toList();
  }

  Future<int> deleteLaporan(int id) async {
    final db = await database;
    return await db.delete('laporan', where: 'id = ?', whereArgs: [id]);
  }
}