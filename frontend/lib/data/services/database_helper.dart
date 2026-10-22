import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const String _webSessionKey = 'local_user_session';
  static const String _webOfflineBookingsKey = 'local_offline_bookings_v1';

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database;
  }

  Future<Database?> _initDatabase() async {
    if (kIsWeb) return null;

    try {
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
    } catch (e) {
      debugPrint('SQLite init error (platform may not support sqflite): $e');
      return null;
    }
  }

  // Quản lý phiên trong user_session (Hỗ trợ cả Mobile SQLite và Web SharedPreferences)
  Future<void> saveUserSession({
    required int userId,
    required String fullName,
    required String phoneNumber,
    String? email,
    required String role,
    int walletBalance = 0,
    required String accessToken,
  }) async {
    final sessionData = {
      'user_id': userId,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'email': email,
      'role': role,
      'wallet_balance': walletBalance,
      'access_token': accessToken,
      'logged_in_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_webSessionKey, jsonEncode(sessionData));
      return;
    }

    try {
      final db = await database;
      if (db != null) {
        await db.insert(
          'user_session',
          sessionData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        return;
      }
    } catch (e) {
      debugPrint('SQLite save error: $e');
    }

    // Fallback to SharedPreferences if SQLite failed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_webSessionKey, jsonEncode(sessionData));
  }

  Future<Map<String, dynamic>?> getUserSession() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_webSessionKey);
      if (raw != null) {
        return jsonDecode(raw) as Map<String, dynamic>;
      }
      return null;
    }

    try {
      final db = await database;
      if (db != null) {
        final List<Map<String, dynamic>> maps = await db.query('user_session', limit: 1);
        if (maps.isNotEmpty) {
          return maps.first;
        }
      }
    } catch (e) {
      debugPrint('SQLite get error: $e');
    }

    // Fallback to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_webSessionKey);
    if (raw != null) {
      return jsonDecode(raw) as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> clearUserSession() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_webSessionKey);
      return;
    }

    try {
      final db = await database;
      if (db != null) {
        await db.delete('user_session');
      }
    } catch (e) {
      debugPrint('SQLite clear error: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_webSessionKey);
  }

  // =========================================================================
  // MODULE 5: QUẢN LÝ VÉ ĐIỆN TỬ NGOẠI TUYẾN (OFFLINE QR PASS - offline_bookings)
  // =========================================================================

  /// Lưu danh sách vé đồng bộ từ Server xuống bảng SQLite `offline_bookings`
  Future<void> saveOfflineBookings(List<Map<String, dynamic>> rows) async {
    try {
      final db = await database;
      if (db != null) {
        final batch = db.batch();
        for (final row in rows) {
          batch.insert(
            'offline_bookings',
            _sanitizeOfflineRow(row),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      }
    } catch (e) {
      debugPrint('SQLite saveOfflineBookings error: $e');
    }

    // Luôn đồng bộ bản sao vào SharedPreferences để hỗ trợ cả Web / Desktop test
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_webOfflineBookingsKey, jsonEncode(rows));
    } catch (e) {
      debugPrint('SharedPreferences saveOfflineBookings error: $e');
    }
  }

  /// Lưu hoặc cập nhật 1 vé đơn lẻ vào SQLite `offline_bookings`
  Future<void> upsertOfflineBooking(Map<String, dynamic> row) async {
    try {
      final db = await database;
      if (db != null) {
        await db.insert(
          'offline_bookings',
          _sanitizeOfflineRow(row),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      debugPrint('SQLite upsertOfflineBooking error: $e');
    }

    try {
      final current = await getOfflineBookings();
      final code = row['booking_code']?.toString() ?? '';
      final updated = <Map<String, dynamic>>[
        row,
        ...current.where((item) => item['booking_code']?.toString() != code),
      ];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_webOfflineBookingsKey, jsonEncode(updated));
    } catch (e) {
      debugPrint('SharedPreferences upsertOfflineBooking error: $e');
    }
  }

  /// Đọc danh sách vé từ SQLite `offline_bookings` khi mất kết nối mạng (Offline Mode)
  Future<List<Map<String, dynamic>>> getOfflineBookings() async {
    if (!kIsWeb) {
      try {
        final db = await database;
        if (db != null) {
          final rows = await db.query(
            'offline_bookings',
            orderBy: 'play_date DESC, created_at DESC',
          );
          if (rows.isNotEmpty) {
            return rows.map((r) => Map<String, dynamic>.from(r)).toList();
          }
        }
      } catch (e) {
        debugPrint('SQLite getOfflineBookings error: $e');
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_webOfflineBookingsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
    } catch (e) {
      debugPrint('SharedPreferences getOfflineBookings error: $e');
    }

    return [];
  }

  /// Cập nhật trạng thái vé trong SQLite sau khi Hủy vé hoặc Check-in
  Future<void> updateOfflineBookingStatus(
    String bookingCode, {
    required String status,
    bool? isCheckedIn,
  }) async {
    try {
      final db = await database;
      if (db != null) {
        final values = <String, Object?>{
          'status': status,
          if (isCheckedIn != null) 'is_checked_in': isCheckedIn ? 1 : 0,
        };
        await db.update(
          'offline_bookings',
          values,
          where: 'booking_code = ?',
          whereArgs: [bookingCode],
        );
      }
    } catch (e) {
      debugPrint('SQLite updateOfflineBookingStatus error: $e');
    }

    try {
      final list = await getOfflineBookings();
      for (final item in list) {
        if (item['booking_code']?.toString() == bookingCode) {
          item['status'] = status;
          if (isCheckedIn != null) {
            item['is_checked_in'] = isCheckedIn ? 1 : 0;
          }
        }
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_webOfflineBookingsKey, jsonEncode(list));
    } catch (e) {
      debugPrint('SharedPreferences updateOfflineBookingStatus error: $e');
    }
  }

  Map<String, Object?> _sanitizeOfflineRow(Map<String, dynamic> row) {
    return {
      'booking_code': row['booking_code']?.toString() ?? '',
      'venue_id': (row['venue_id'] as num?)?.toInt() ?? 1,
      'venue_name': row['venue_name']?.toString() ?? '',
      'sport_name': row['sport_name']?.toString() ?? '',
      'sub_venue_name': row['sub_venue_name']?.toString() ?? '',
      'address': row['address']?.toString() ?? '',
      'play_date': row['play_date']?.toString() ?? '',
      'time_slots': row['time_slots']?.toString() ?? '',
      'user_role_in_match': row['user_role_in_match']?.toString() ?? 'Host',
      'total_price': (row['total_price'] as num?)?.toInt() ?? 0,
      'deposit_amount': (row['deposit_amount'] as num?)?.toInt() ?? 0,
      'status': row['status']?.toString() ?? 'Upcoming',
      'qr_payload': row['qr_payload']?.toString() ?? '',
      'is_checked_in': row['is_checked_in'] == true || row['is_checked_in'] == 1 ? 1 : 0,
      'notification_id': (row['notification_id'] as num?)?.toInt() ?? 100,
      'created_at': row['created_at']?.toString() ?? DateTime.now().toIso8601String(),
    };
  }
}
