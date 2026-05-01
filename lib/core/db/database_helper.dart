import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _dbName = 'quran.db';
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, _dbName);

    if (!await File(dbPath).exists()) {
      try {
        final data = await rootBundle.load('assets/db/$_dbName');
        final bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(dbPath).writeAsBytes(bytes, flush: true);
      } catch (e) {
        // If the asset copy fails, openDatabase will create an empty DB.
        // The UI handles missing data gracefully via FutureBuilder error states.
      }
    }

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        // Empty handler so sqflite doesn't throw on a freshly created DB.
      },
    );
  }
}

