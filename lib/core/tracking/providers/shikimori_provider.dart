import '../tracker_provider.dart';
import '../tracking_event.dart';

/// Заглушка интеграции с Shikimori (docs/documentation.md, п.3.3).
///
/// TODO: реализовать OAuth-аутентификацию и вызовы Shikimori GraphQL/REST
/// API вместо [UnimplementedError].
class ShikimoriProvider implements TrackerProvider {
  @override
  String get id => 'shikimori';

  @override
  String get displayName => 'Shikimori';

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
