import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models.dart'; // Import your models
import 'dart:async'; // Import StreamController

class LocalDatabaseService {
  static final LocalDatabaseService _instance =
      LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  static LocalDatabaseService get instance => _instance;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> init() async {
    await database; // Ensure database is initialized on app start
  }

  Future<Database> _initDatabase() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'novel_reader.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create favorites table
    await db.execute('''
      CREATE TABLE favorites (
        id TEXT PRIMARY KEY,
        nome TEXT,
        desc TEXT,
        cover TEXT,
        genres TEXT,   -- Stored as JSON string
        chapters TEXT  -- Stored as JSON string
      )
    ''');

    // Create history table
    await db.execute('''
      CREATE TABLE history (
        novelId TEXT,
        chapterId TEXT,
        novelName TEXT,
        chapterTitle TEXT,
        readAt INTEGER, -- Store as Unix timestamp
        PRIMARY KEY (novelId, chapterId)
      )
    ''');
  }

  // --- Favorites Management ---
  Future<void> toggleFavorite(Novel novel) async {
    final db = await database;
    final existing = await db.query(
      'favorites',
      where: 'id = ?',
      whereArgs: [novel.id],
    );

    if (existing.isNotEmpty) {
      await db.delete('favorites', where: 'id = ?', whereArgs: [novel.id]);
      print('Novel ${novel.nome} removed from favorites.');
    } else {
      await db.insert(
        'favorites',
        novel.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('Novel ${novel.nome} added to favorites.');
    }
  }

  Future<bool> isNovelFavorited(String novelId) async {
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'id = ?',
      whereArgs: [novelId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<List<Novel>> getFavorites() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('favorites');
    return List.generate(maps.length, (i) {
      return Novel.fromMap(maps[i]);
    });
  }

  // Use a StreamController to expose changes to the UI
  // This is a common pattern for local databases to mimic Firestore's real-time updates.
  final StreamController<List<Novel>> _favoritesStreamController =
      StreamController<List<Novel>>.broadcast();
  Stream<List<Novel>> getFavoritesStream() => _favoritesStreamController.stream;

  // Method to manually update the favorites stream (call after toggleFavorite)
  Future<void> refreshFavoritesStream() async {
    final favorites = await getFavorites();
    _favoritesStreamController.add(favorites);
  }

  // --- History Management ---
  Future<void> addChapterToHistory(Novel novel, ChapterSummary chapter) async {
    final db = await database;
    await db.insert(
      'history',
      {
        'novelId': novel.id,
        'chapterId': chapter.id,
        'novelName': novel.nome,
        'chapterTitle': chapter.title,
        'readAt': DateTime.now().millisecondsSinceEpoch, // Unix timestamp
      },
      conflictAlgorithm: ConflictAlgorithm.replace, // Update if exists
    );
    print('Chapter ${chapter.title} of ${novel.nome} added to history.');
    refreshHistoryStream(); // Refresh the history stream
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'history',
      orderBy: 'readAt DESC', // Order by most recent
    );
    return maps;
  }

  final StreamController<List<Map<String, dynamic>>> _historyStreamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  Stream<List<Map<String, dynamic>>> getHistoryStream() =>
      _historyStreamController.stream;

  Future<void> refreshHistoryStream() async {
    final history = await getHistory();
    _historyStreamController.add(history);
  }

  // Novo método para limpar todo o histórico
  Future<void> clearAllHistory() async {
    final db = await database;
    await db.delete('history');
    print('Todo o histórico de leitura foi limpo.');
    refreshHistoryStream(); // Atualiza o stream após a limpeza
  }

  // Close the database when no longer needed (e.g., on app shutdown)
  Future<void> close() async {
    final db = await database;
    await db.close();
    _favoritesStreamController.close();
    _historyStreamController.close();
  }
}
