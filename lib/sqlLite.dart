import 'dart:async';
import 'dart:ffi';
import 'dart:io' as io;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voice_chatgpt/chat_modal.dart';

class DBHelper {
  static Database? _db;
  static DateTime id = DateTime.now();
  static const String content = 'content';
  static const int type = 1;
  static const String TABLE = 'conversation';
  static const String DB_NAME = 'chat_voice.db';

  Future<Database> get db async => _db ??= await initDb();

  Future<Database> initDb() async {
    //init db
    Database db;
    if (io.Platform.isWindows) {
      sqfliteFfiInit();
      var databaseFactory = databaseFactoryFfi;
      db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      // await db.execute('DROP TABLE IF EXISTS  $TABLE ');
      await db.execute(
          "CREATE TABLE IF NOT EXISTS  $TABLE (ID INTEGER PRIMARY KEY AUTOINCREMENT, time DATETIME, content TEXT, type INTEGER)");
    } else {
      io.Directory documentsDirectory =
          await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, DB_NAME);
      db = await openDatabase(path, version: 2, onCreate: _onCreate);
    }
    return db;
  }

  _onCreate(Database db, int version) async {
    //tạo database
    await db.execute(
        "CREATE TABLE IF NOT EXISTS  $TABLE (ID INTEGER PRIMARY KEY AUTOINCREMENT, time DATETIME, content TEXT, type INTEGER)");
  }

  Future<List<Map<String, dynamic>>> getChatMessage() async {
    //get list employees đơn giản
    var dbClient = await db;
    final List<Map<String, dynamic>> results = await dbClient
        .query('conversation', columns: ["time", "content", "type"]);
    return results;
  }

  Future save(ChatMessage chat) async {
    var dbClient = await db;
    return dbClient.insert('conversation', chat.toMap());
  }

  Future clearTable() async {
    var dbClient = await db;
    return dbClient.execute('DELETE FROM $TABLE ');
  }

  Future initAgainTable() async {
    var dbClient = await db;
    return dbClient.execute(
        "CREATE TABLE IF NOT EXISTS  $TABLE (ID INTEGER PRIMARY KEY AUTOINCREMENT, time DATETIME, content TEXT, type INTEGER");
  }

  Future close() async {
    //close khi không sử dụng
    var dbClient = await db;
    dbClient.close();
  }
}
