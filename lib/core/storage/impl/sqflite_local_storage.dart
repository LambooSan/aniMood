import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../models/resource.dart';
import '../local_storage.dart';
import '../models/bookmark.dart';
import '../models/history_entry.dart';

/// Реализация [LocalStorage] поверх `sqflite` (docs/architecture.md, п.5).
///
/// `sqflite` не имеет реализации под Linux/Windows-десктоп — там
/// используется `sqflite_common_ffi` (тот же API поверх sqlite3 через
/// FFI), см. [SqfliteLocalStorage.open].
///
/// [cacheSizeBytes] отражает объём сериализованных метаданных ресурсов
/// (URL'ы, качество и т.п.) в БД, а не размер скачанных файлов — реальный
/// файловый download manager для серий/страниц пока не реализован
/// (TODO), это только индекс кеша.
class SqfliteLocalStorage implements LocalStorage {
  SqfliteLocalStorage._(this._db);

  final Database _db;

  static Future<SqfliteLocalStorage> open({String? path}) async {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = path ?? p.join(await getDatabasesPath(), 'animood.db');
    final db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE history (
            title_id TEXT NOT NULL,
            source_id TEXT NOT NULL,
            entry_id TEXT NOT NULL,
            updated_at INTEGER NOT NULL,
            position_seconds REAL,
            page_index INTEGER,
            PRIMARY KEY (title_id, entry_id)
          )
        ''');
        await db.execute('''
          CREATE TABLE bookmarks (
            title_id TEXT NOT NULL,
            source_id TEXT NOT NULL,
            added_at INTEGER NOT NULL,
            PRIMARY KEY (title_id, source_id)
          )
        ''');
        await db.execute('''
          CREATE TABLE resource_cache (
            entry_id TEXT NOT NULL,
            resource_index INTEGER NOT NULL,
            data TEXT NOT NULL,
            PRIMARY KEY (entry_id, resource_index)
          )
        ''');
      },
    );
    return SqfliteLocalStorage._(db);
  }

  Future<void> close() => _db.close();

  // --- История ---

  @override
  Future<void> saveProgress(HistoryEntry entry) {
    return _db.insert('history', {
      'title_id': entry.titleId,
      'source_id': entry.sourceId,
      'entry_id': entry.entryId,
      'updated_at': entry.updatedAt.millisecondsSinceEpoch,
      'position_seconds': entry.positionSeconds,
      'page_index': entry.pageIndex,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<HistoryEntry?> getProgress(String titleId, String entryId) async {
    final rows = await _db.query(
      'history',
      where: 'title_id = ? AND entry_id = ?',
      whereArgs: [titleId, entryId],
      limit: 1,
    );
    return rows.isEmpty ? null : _historyFromRow(rows.first);
  }

  @override
  Future<List<HistoryEntry>> recentHistory({int limit = 50}) async {
    final rows = await _db.query(
      'history',
      orderBy: 'updated_at DESC',
      limit: limit,
    );
    return rows.map(_historyFromRow).toList(growable: false);
  }

  HistoryEntry _historyFromRow(Map<String, Object?> row) {
    return HistoryEntry(
      titleId: row['title_id']! as String,
      sourceId: row['source_id']! as String,
      entryId: row['entry_id']! as String,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at']! as int),
      positionSeconds: row['position_seconds'] as double?,
      pageIndex: row['page_index'] as int?,
    );
  }

  // --- Закладки ---

  @override
  Future<void> addBookmark(Bookmark bookmark) {
    return _db.insert('bookmarks', {
      'title_id': bookmark.titleId,
      'source_id': bookmark.sourceId,
      'added_at': bookmark.addedAt.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> removeBookmark(String titleId, String sourceId) {
    return _db.delete(
      'bookmarks',
      where: 'title_id = ? AND source_id = ?',
      whereArgs: [titleId, sourceId],
    );
  }

  @override
  Future<List<Bookmark>> get bookmarks async {
    final rows = await _db.query('bookmarks', orderBy: 'added_at DESC');
    return rows
        .map(
          (row) => Bookmark(
            titleId: row['title_id']! as String,
            sourceId: row['source_id']! as String,
            addedAt: DateTime.fromMillisecondsSinceEpoch(
              row['added_at']! as int,
            ),
          ),
        )
        .toList(growable: false);
  }

  // --- Кеш ресурсов ---

  @override
  Future<List<Resource>?> getCachedResources(String entryId) async {
    final rows = await _db.query(
      'resource_cache',
      where: 'entry_id = ?',
      whereArgs: [entryId],
      orderBy: 'resource_index ASC',
    );
    if (rows.isEmpty) return null;
    return rows
        .map(
          (row) => Resource.fromJson(
            jsonDecode(row['data']! as String) as Map<String, dynamic>,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> cacheResources(String entryId, List<Resource> resources) async {
    final batch = _db.batch();
    batch.delete('resource_cache', where: 'entry_id = ?', whereArgs: [entryId]);
    for (var i = 0; i < resources.length; i++) {
      batch.insert('resource_cache', {
        'entry_id': entryId,
        'resource_index': i,
        'data': jsonEncode(resources[i].toJson()),
      });
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> evictCache(String entryId) {
    return _db.delete(
      'resource_cache',
      where: 'entry_id = ?',
      whereArgs: [entryId],
    );
  }

  @override
  Future<int> cacheSizeBytes() async {
    final result = await _db.rawQuery(
      'SELECT SUM(LENGTH(data)) AS total FROM resource_cache',
    );
    return (result.first['total'] as int?) ?? 0;
  }
}
