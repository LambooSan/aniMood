import '../models/resource.dart';

/// Core Engine постраничного чтения манги/манхвы (docs/architecture.md,
/// п.4.2 — Reader pipeline).
///
/// Отвечает за текущую позицию чтения и подгрузку соседних страниц вперёд,
/// чтобы прокрутка оставалась плавной без ожидания сети.
abstract class ReaderEngine {
  int get currentPageIndex;

  int get pageCount;

  Future<void> loadPages(List<PageImage> pages);

  Future<void> goToPage(int index);

  /// Явный прогрев кеша соседних страниц вокруг [index]; вызывается
  /// движком автоматически при [goToPage], но может быть форсирован UI.
  Future<void> prefetchAround(int index, {int radius = 2});
}
