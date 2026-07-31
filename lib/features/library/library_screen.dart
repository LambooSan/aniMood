import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_storage_provider.dart';
import '../../core/storage/models/bookmark.dart';
import '../../core/storage/models/history_entry.dart';

/// История и закладки (docs/documentation.md, п.3.3 — "Кастомизация и
/// Бекап"), читает [LocalStorage] через [localStorageProvider].
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(localStorageProvider);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [Tab(text: 'История'), Tab(text: 'Закладки')],
          ),
          Expanded(
            child: TabBarView(
              children: [
                FutureBuilder<List<HistoryEntry>>(
                  future: storage.recentHistory(),
                  builder: (context, snapshot) {
                    final items = snapshot.data;
                    if (items == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (items.isEmpty) {
                      return const Center(child: Text('История пуста'));
                    }
                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final entry = items[index];
                        return ListTile(
                          title: Text('${entry.titleId} · ${entry.sourceId}'),
                          subtitle: Text('Серия/глава ${entry.entryId}'),
                        );
                      },
                    );
                  },
                ),
                FutureBuilder<List<Bookmark>>(
                  future: storage.bookmarks,
                  builder: (context, snapshot) {
                    final items = snapshot.data;
                    if (items == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (items.isEmpty) {
                      return const Center(child: Text('Нет закладок'));
                    }
                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final bookmark = items[index];
                        return ListTile(
                          leading: const Icon(Icons.bookmark),
                          title: Text(bookmark.titleId),
                          subtitle: Text(bookmark.sourceId),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
