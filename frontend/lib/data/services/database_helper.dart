import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sportspot_local.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // 1. Bảng user_session
        await db.execute('''
          CREATE TABLE IF NOT EXISTS user_session (
            user_id INTEGER PRIMARY KEY,
            full_name TEXT NOT NULL,
            phone_number TEXT NOT NULL,
            email TEXT,
            role TEXT NOT NULL,
            wallet_balance INTEGER NOT NULL DEFAULT 0,
            access_token TEXT NOT NULL,
            logged_in_at TEXT NOT NULL
          )
        ''');

        // 2. Bảng app_settings
        await db.execute('''
          CREATE TABLE IF NOT EXISTS app_settings (
            setting_key TEXT PRIMARY KEY,
            setting_value TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // 3. Bảng offline_bookings
        await db.execute('''
          CREATE TABLE IF NOT EXISTS offline_bookings (
            booking_code TEXT PRIMARY KEY,
            venue_id INTEGER NOT NULL,
            venue_name TEXT NOT NULL,
            sport_name TEXT NOT NULL,
            sub_venue_name TEXT NOT NULL,
            address TEXT NOT NULL,
            play_date TEXT NOT NULL,
            time_slots TEXT NOT NULL,
            user_role_in_match TEXT NOT NULL,
            total_price INTEGER NOT NULL,
            deposit_amount INTEGER NOT NULL,
            status TEXT NOT NULL,
            qr_payload TEXT NOT NULL,
            is_checked_in INTEGER NOT NULL DEFAULT 0,
            notification_id INTEGER NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        // 4. Bảng favorites
        await db.execute('''
          CREATE TABLE IF NOT EXISTS favorites (
            venue_id INTEGER PRIMARY KEY,
            sport_name TEXT NOT NULL,
            venue_name TEXT NOT NULL,
            address TEXT NOT NULL,
            image_url TEXT,
            rating REAL NOT NULL DEFAULT 5.0,
            base_price INTEGER NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // Quản lý phiên trong user_session
  Future<void> saveUserSession({
    required int userId,
    required String fullName,
    required String phoneNumber,
    String? email,
    required String role,
    int walletBalance = 0,
    required String accessToken,
  }) async {
    final db = await database;
    await db.insert(
      'user_session',
      {
        'user_id': userId,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'email': email,
        'role': role,
        'wallet_balance': walletBalance,
        'access_token': accessToken,
        'logged_in_at': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getUserSession() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('user_session', limit: 1);
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<void> clearUserSession() async {
    final db = await database;
    await db.delete('user_session');
  }
}
