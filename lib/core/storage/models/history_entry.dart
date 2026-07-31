/// Запись локальной истории просмотра/чтения — прогресс по конкретной
/// [Entry] в рамках тайтла (docs/architecture.md, п.5).
class HistoryEntry {
  const HistoryEntry({
    required this.titleId,
    required this.sourceId,
    required this.entryId,
    required this.updatedAt,
    this.positionSeconds,
    this.pageIndex,
  });

  final String titleId;
  final String sourceId;
  final String entryId;
  final DateTime updatedAt;

  /// Позиция воспроизведения для видео (секунды).
  final double? positionSeconds;

  /// Последняя прочитанная страница для манги/манхвы.
  final int? pageIndex;
}
