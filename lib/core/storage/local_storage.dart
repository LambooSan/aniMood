import '../models/resource.dart';
import 'models/bookmark.dart';
import 'models/history_entry.dart';

/// Локальное хранилище: история, закладки и офлайн-кеш ресурсов
/// (docs/architecture.md, п.5).
///
/// Конкретная реализация (напр. на базе sqflite + файловый кеш) должна
/// быть подставлена при интеграции; здесь описан только контракт.
abstract class LocalStorage {
  // --- История просмотра/чтения ---

  Future<void> saveProgress(HistoryEntry entry);

  Future<HistoryEntry?> getProgress(String titleId, String entryId);

  Future<List<HistoryEntry>> recentHistory({int limit = 50});

  // --- Закладки ---

  Future<void> addBookmark(Bookmark bookmark);

  Future<void> removeBookmark(String titleId, String sourceId);

  Future<List<Bookmark>> get bookmarks;

  // --- Офлайн-кеш ресурсов (скачанные серии/главы) ---

  /// Возвращает локально закешированный [Resource], если он ранее был
  /// скачан для [entryId] — Parser Engine обращается сюда до похода
  /// в сеть (docs/architecture.md, п.5).
  Future<List<Resource>?> getCachedResources(String entryId);

  Future<void> cacheResources(String entryId, List<Resource> resources);

  Future<void> evictCache(String entryId);

  /// Суммарный объём кеша в байтах — для отображения в
  /// "Настройки -> Хранилище" (docs/documentation.md, п.5.2).
  Future<int> cacheSizeBytes();
}
