import '../tracker_provider.dart';
import '../tracking_event.dart';

/// Заглушка интеграции с MyDramaList (docs/documentation.md, п.3.3).
///
/// TODO: реализовать аутентификацию и вызовы MyDramaList API вместо
/// [UnimplementedError].
class MyDramaListProvider implements TrackerProvider {
  @override
  String get id => 'mydramalist';

  @override
  String get displayName => 'MyDramaList';

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
