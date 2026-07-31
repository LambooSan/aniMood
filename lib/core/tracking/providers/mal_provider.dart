import '../tracker_provider.dart';
import '../tracking_event.dart';

/// Заглушка интеграции с MyAnimeList (docs/documentation.md, п.3.3).
///
/// TODO: реализовать OAuth2-аутентификацию и вызовы MAL REST API вместо
/// [UnimplementedError].
class MalProvider implements TrackerProvider {
  @override
  String get id => 'myanimelist';

  @override
  String get displayName => 'MyAnimeList';

  @override
  bool get isAuthenticated => false;

  @override
  Future<void> authenticate() => throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();

  @override
  Future<String?> mapTitle({required String titleId, required String name}) =>
      throw UnimplementedError();

  @override
  Future<void> pushProgress(
    TrackingEvent event, {
    required String remoteTitleId,
  }) =>
      throw UnimplementedError();
}
