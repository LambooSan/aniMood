import '../tracker_provider.dart';
import '../tracking_event.dart';

/// Заглушка интеграции с AniList (docs/documentation.md, п.3.3).
///
/// TODO: реализовать OAuth-аутентификацию и вызовы AniList GraphQL API
/// вместо [UnimplementedError].
class AniListProvider implements TrackerProvider {
  @override
  String get id => 'anilist';

  @override
  String get displayName => 'AniList';

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
