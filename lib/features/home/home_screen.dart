import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_storage_provider.dart';
import '../../core/storage/models/history_entry.dart';

/// Стартовый экран — продолжение просмотра/чтения (docs/documentation.md,
/// п.3.3 — локальная история) и подборки по подключённым каталогам.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(localStorageProvider);

    return FutureBuilder<List<HistoryEntry>>(
      future: storage.recentHistory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data!;
        if (items.isEmpty) {
          return const Center(child: Text('Пока нет истории просмотра/чтения'));
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final entry = items[index];
            return ListTile(
              leading: const Icon(Icons.play_circle_outline),
              title: Text('${entry.titleId} · ${entry.sourceId}'),
              subtitle: Text(_subtitleFor(entry)),
            );
          },
        );
      },
    );
  }

  String _subtitleFor(HistoryEntry entry) {
    if (entry.positionSeconds != null) {
      return 'Серия ${entry.entryId} · ${entry.positionSeconds!.round()}с';
    }
    if (entry.pageIndex != null) {
      return 'Глава ${entry.entryId} · стр. ${entry.pageIndex}';
    }
    return 'Серия/глава ${entry.entryId}';
  }
}
