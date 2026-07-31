/// Закладка на тайтл (docs/documentation.md, п.3.3 — гибкая система
/// закладок).
class Bookmark {
  const Bookmark({
    required this.titleId,
    required this.sourceId,
    required this.addedAt,
  });

  final String titleId;
  final String sourceId;
  final DateTime addedAt;
}
