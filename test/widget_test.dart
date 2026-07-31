import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:animood/core/models/resource.dart';
import 'package:animood/core/storage/local_storage.dart';
import 'package:animood/core/storage/local_storage_provider.dart';
import 'package:animood/core/storage/models/bookmark.dart';
import 'package:animood/core/storage/models/history_entry.dart';
import 'package:animood/main.dart';

/// Лёгкая in-memory реализация для виджет-тестов — настоящий
/// [SqfliteLocalStorage] требует платформенных каналов (sqflite/FFI),
/// недоступных в `flutter test`.
class _FakeLocalStorage implements LocalStorage {
  final List<HistoryEntry> _history = [];
  final List<Bookmark> _bookmarks = [];

  @override
  Future<void> saveProgress(HistoryEntry entry) async => _history.add(entry);

  @override
  Future<HistoryEntry?> getProgress(String titleId, String entryId) async =>
      null;

  @override
  Future<List<HistoryEntry>> recentHistory({int limit = 50}) async =>
      _history;

  @override
  Future<void> addBookmark(Bookmark bookmark) async => _bookmarks.add(bookmark);

  @override
  Future<void> removeBookmark(String titleId, String sourceId) async {}

  @override
  Future<List<Bookmark>> get bookmarks async => _bookmarks;

  @override
  Future<List<Resource>?> getCachedResources(String entryId) async => null;

  @override
  Future<void> cacheResources(String entryId, List<Resource> resources) async {}

  @override
  Future<void> evictCache(String entryId) async {}

  @override
  Future<int> cacheSizeBytes() async => 0;
}

void main() {
  testWidgets('AniMoodApp запускается и показывает навигацию', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(_FakeLocalStorage()),
        ],
        child: const AniMoodApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Главная'), findsOneWidget);
    expect(find.text('Поиск'), findsOneWidget);
    expect(find.text('Библиотека'), findsOneWidget);
    expect(find.text('Настройки'), findsOneWidget);
  });
}
