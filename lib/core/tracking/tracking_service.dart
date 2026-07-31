import 'tracker_provider.dart';
import 'tracking_event.dart';

/// Оркестрирует отправку прогресса во все аутентифицированные
/// [TrackerProvider]. Работает поверх Local Storage и не зависит от того,
/// какой Source Module предоставил контент (docs/architecture.md, п.6).
///
/// События, которые не удалось отправить (нет сети/сервис недоступен),
/// остаются в очереди и досылаются при следующем [flushPending] —
/// конфликт с более новым локальным изменением разрешается по принципу
/// "побеждает последнее изменение" (last-write-wins).
class TrackingService {
  TrackingService(this.providers);

  final List<TrackerProvider> providers;

  final Map<String, TrackingEvent> _pending = {};

  String _key(TrackingEvent e) => '${e.sourceId}:${e.titleId}';

  /// Ставит событие в очередь; более новое событие для того же тайтла
  /// замещает более старое непосланное (last-write-wins).
  void enqueue(TrackingEvent event) {
    final key = _key(event);
    final existing = _pending[key];
    if (existing == null || event.occurredAt.isAfter(existing.occurredAt)) {
      _pending[key] = event;
    }
  }

  /// Пытается разослать все ожидающие события по аутентифицированным
  /// провайдерам. Успешно отправленные события удаляются из очереди;
  /// неудачные остаются для следующей попытки.
  Future<void> flushPending() async {
    final active = providers.where((p) => p.isAuthenticated).toList();
    if (active.isEmpty) return;

    final sentKeys = <String>[];

    for (final entry in _pending.entries) {
      final event = entry.value;
      var sentToAny = false;

      for (final provider in active) {
        try {
          final remoteId = await provider.mapTitle(
            titleId: event.titleId,
            name: event.titleId,
          );
          if (remoteId == null) continue;
          await provider.pushProgress(event, remoteTitleId: remoteId);
          sentToAny = true;
        } catch (_) {
          // Изолируем сбой конкретного провайдера — остальные продолжают
          // получать событие; событие остаётся в очереди для повтора.
        }
      }

      if (sentToAny) {
        sentKeys.add(entry.key);
      }
    }

    sentKeys.forEach(_pending.remove);
  }

  int get pendingCount => _pending.length;
}
