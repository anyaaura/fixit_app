import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'service_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fixit.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4, // Naikkan versi database untuk memperbarui struktur kolom
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_pelanggan TEXT NOT NULL,
        nomor_hp TEXT NOT NULL DEFAULT '',
        jenis_perangkat TEXT NOT NULL,
        merek TEXT NOT NULL DEFAULT '',
        model_tipe TEXT NOT NULL DEFAULT '',
        keluhan_kerusakan TEXT NOT NULL,
        tanggal_masuk TEXT NOT NULL DEFAULT '',
        estimasi_biaya REAL NOT NULL DEFAULT 0.0,
        status_progres TEXT NOT NULL,
        status_bayar TEXT NOT NULL DEFAULT 'Belum Lunas'
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Jika versi lama, kita buat ulang tabel agar bersih dan sesuai dengan format Supabase
    if (oldVersion < 4) {
      await db.execute('DROP TABLE IF EXISTS services');
      await _createDB(db, newVersion);
    }
  }

  Future<int> insertService(ServiceItem item) async {
    final db = await instance.database;
    return await db.insert('services', item.toMap());
  }

  Future<List<ServiceItem>> getAllServices() async {
    final db = await instance.database;
    final result = await db.query('services', orderBy: 'id DESC');
    return result.map((json) => ServiceItem.fromMap(json)).toList();
  }

  Future<List<ServiceItem>> searchServices(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'services',
      where: 'nama_pelanggan LIKE ? OR jenis_perangkat LIKE ? OR merek LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'id DESC',
    );
    return result.map((json) => ServiceItem.fromMap(json)).toList();
  }

  Future<int> updateStatus(int id, String statusProgres) async {
    final db = await instance.database;
    return await db.update(
      'services',
      {'status_progres': statusProgres},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updatePaymentStatus(int id, String statusBayar) async {
    final db = await instance.database;
    return await db.update(
      'services',
      {'status_bayar': statusBayar},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateService(ServiceItem item) async {
    final db = await instance.database;
    return await db.update(
      'services',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteService(int id) async {
    final db = await instance.database;
    return await db.delete(
      'services',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}