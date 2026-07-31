import 'tracking_event.dart';

/// Контракт внешнего трекера прогресса (Shikimori/AniList/MyAnimeList/
/// MyDramaList), см. docs/architecture.md, п.6.
///
/// Реализации инкапсулируют аутентификацию и API конкретного сервиса;
/// сопоставление локального тайтла с тайтлом трекера выполняется здесь же,
/// по метаданным, а не по источнику контента.
abstract class TrackerProvider {
  String get id;

  String get displayName;

  bool get isAuthenticated;

  Future<void> authenticate();

  Future<void> signOut();

  /// Сопоставляет локальный тайтл с идентификатором тайтла в трекере.
  /// Возвращает `null`, если сопоставление не найдено.
  Future<String?> mapTitle({required String titleId, required String name});

  /// Отправляет изменение прогресса в трекер.
  Future<void> pushProgress(TrackingEvent event, {required String remoteTitleId});
}
