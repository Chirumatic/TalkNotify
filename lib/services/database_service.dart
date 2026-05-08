import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/message_model.dart';

/// Service for managing local database operations
class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('talknotify.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE messages (
        id $idType,
        senderName $textType,
        messageContent $textType,
        appSource $textType,
        timestamp $textType,
        isRead $intType,
        isGroupMessage INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  /// Insert a new message
  Future<MessageModel> insertMessage(MessageModel message) async {
    final db = await instance.database;
    final id = await db.insert('messages', message.toMap());
    return message.copyWith(id: id);
  }

  /// Get all messages
  Future<List<MessageModel>> getAllMessages() async {
    final db = await instance.database;
    const orderBy = 'timestamp DESC';
    final result = await db.query('messages', orderBy: orderBy);
    return result.map((json) => MessageModel.fromMap(json)).toList();
  }

  /// Get messages by app source
  Future<List<MessageModel>> getMessagesByApp(String appSource) async {
    final db = await instance.database;
    final result = await db.query(
      'messages',
      where: 'appSource = ?',
      whereArgs: [appSource],
      orderBy: 'timestamp DESC',
    );
    return result.map((json) => MessageModel.fromMap(json)).toList();
  }

  /// Get latest message
  Future<MessageModel?> getLatestMessage() async {
    final db = await instance.database;
    final result = await db.query(
      'messages',
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return MessageModel.fromMap(result.first);
    }
    return null;
  }

  /// Mark message as read
  Future<int> markAsRead(int id) async {
    final db = await instance.database;
    return db.update(
      'messages',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a message
  Future<int> deleteMessage(int id) async {
    final db = await instance.database;
    return await db.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Clear all messages
  Future<int> clearAllMessages() async {
    final db = await instance.database;
    return await db.delete('messages');
  }

  /// Close database
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
