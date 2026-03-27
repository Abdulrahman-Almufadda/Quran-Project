import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../models/surah.dart';
import '../models/ayah.dart';
import '../models/bookmark.dart';
import 'database_helper.dart';

class QuranRepository {
  final DatabaseHelper _dbHelper;
  // In-memory cache used on web when SQLite isn't available.
  static List<Map<String, dynamic>>? _webSurahs;
  static List<Map<String, dynamic>>? _webAyahs;

  QuranRepository(this._dbHelper);

  Future<Database> get _db async => _dbHelper.database;

  Future<List<Surah>> getSurahs() async {
    if (kIsWeb) {
      await _ensureWebDataLoaded();
      return (_webSurahs ?? []).map((e) => Surah.fromMap(e)).toList();
    }

    try {
      final db = await _db;
      final result = await db.query(
        'surahs',
        orderBy: 'id ASC',
      );
      return result.map((e) => Surah.fromMap(e)).toList();
    } catch (_) {
      return <Surah>[];
    }
  }

  Future<List<Ayah>> getAyahsBySurah(int surahId) async {
    if (kIsWeb) {
      await _ensureWebDataLoaded();
      final filtered = (_webAyahs ?? []).where((m) => m['surah_id'] == surahId).toList();
      filtered.sort((a, b) => (a['ayah_number'] as int).compareTo(b['ayah_number'] as int));
      return filtered.map((e) => Ayah.fromMap(e)).toList();
    }

    try {
      final db = await _db;
      final result = await db.query(
        'ayahs',
        where: 'surah_id = ?',
        whereArgs: [surahId],
        orderBy: 'ayah_number ASC',
      );
      return result.map((e) => Ayah.fromMap(e)).toList();
    } catch (_) {
      return <Ayah>[];
    }
  }

  static const int totalPages = 604;

  Future<List<Ayah>> getAyahsByPage(int page) async {
    if (kIsWeb) {
      await _ensureWebDataLoaded();
      final filtered = (_webAyahs ?? []).where((m) => m['page'] == page).toList();
      filtered.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
      return filtered.map((e) => Ayah.fromMap(e)).toList();
    }

    try {
      final db = await _db;
      final result = await db.query(
        'ayahs',
        where: 'page = ?',
        whereArgs: [page],
        orderBy: 'id ASC',
      );
      return result.map((e) => Ayah.fromMap(e)).toList();
    } catch (_) {
      return <Ayah>[];
    }
  }

  Future<int> getFirstPageOfSurah(int surahId) async {
    if (kIsWeb) {
      await _ensureWebDataLoaded();
      final filtered = (_webAyahs ?? []).where((m) => m['surah_id'] == surahId).toList();
      if (filtered.isEmpty) return 1;
      filtered.sort((a, b) => (a['ayah_number'] as int).compareTo(b['ayah_number'] as int));
      return (filtered.first['page'] as int?) ?? 1;
    }

    try {
      final db = await _db;
      final result = await db.query(
        'ayahs',
        columns: ['page'],
        where: 'surah_id = ?',
        whereArgs: [surahId],
        orderBy: 'ayah_number ASC',
        limit: 1,
      );
      if (result.isEmpty) return 1;
      return (result.first['page'] as int?) ?? 1;
    } catch (_) {
      return 1;
    }
  }

  Future<List<Ayah>> searchAyahs(String query) async {
    if (kIsWeb) {
      await _ensureWebDataLoaded();
      final q = query.trim();
      final res = (_webAyahs ?? []).where((m) => (m['text_ar'] as String).contains(q)).toList();
      return res.map((e) => Ayah.fromMap(e)).toList();
    }

    try {
      final db = await _db;
      final result = await db.rawQuery(
        '''
      SELECT a.*
      FROM ayahs_fts f
      JOIN ayahs a ON a.id = f.rowid
      WHERE ayahs_fts MATCH ?
      ORDER BY a.surah_id, a.ayah_number
      ''',
        [query],
      );
      return result.map((e) => Ayah.fromMap(e)).toList();
    } catch (_) {
      return <Ayah>[];
    }
  }

  static Future<void> _ensureWebDataLoaded() async {
    if (_webAyahs != null && _webSurahs != null) return;
    try {
      final jsonStr = await rootBundle.loadString('assets/db/quran_sample.json');
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      _webSurahs = List<Map<String, dynamic>>.from(data['surahs'] as List);
      _webAyahs = List<Map<String, dynamic>>.from(data['ayahs'] as List);
    } catch (_) {
      _webSurahs = <Map<String, dynamic>>[];
      _webAyahs = <Map<String, dynamic>>[];
    }
  }

  Future<void> addBookmark(int surahId, int ayahNumber) async {
    final db = await _db;
    await db.insert('bookmarks', {
      'surah_id': surahId,
      'ayah_number': ayahNumber,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> removeBookmark(int surahId, int ayahNumber) async {
    final db = await _db;
    await db.delete(
      'bookmarks',
      where: 'surah_id = ? AND ayah_number = ?',
      whereArgs: [surahId, ayahNumber],
    );
  }

  Future<bool> isBookmarked(int surahId, int ayahNumber) async {
    final db = await _db;
    final result = await db.query(
      'bookmarks',
      where: 'surah_id = ? AND ayah_number = ?',
      whereArgs: [surahId, ayahNumber],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<List<Bookmark>> getBookmarks() async {
    final db = await _db;
    final result = await db.query(
      'bookmarks',
      orderBy: 'created_at DESC',
    );
    return result.map((e) => Bookmark.fromMap(e)).toList();
  }
}

