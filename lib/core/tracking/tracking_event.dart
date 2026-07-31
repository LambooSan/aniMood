/// Событие изменения локального прогресса, ожидающее отправки во внешний
/// трекер (docs/architecture.md, п.6).
class TrackingEvent {
  const TrackingEvent({
    required this.titleId,
    required this.sourceId,
    required this.progressNumber,
    required this.occurredAt,
  });

  final String titleId;
  final String sourceId;

  /// Номер последней просмотренной серии / прочитанной главы.
  final double progressNumber;
  final DateTime occurredAt;
}
