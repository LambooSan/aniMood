import '../models/resource.dart';
import 'playback_state.dart';

/// Core Engine видеовоспроизведения (docs/architecture.md, п.4.1 — Video
/// pipeline). Не зависит от Parser Engine и от конкретного источника —
/// принимает уже нормализованный [StreamLink].
///
/// Конкретная реализация (напр. на базе пакета `video_player`) должна быть
/// подставлена при интеграции; здесь описан только контракт.
abstract class VideoPlayerEngine {
  PlaybackState get state;

  Duration get position;

  Duration get duration;

  double get playbackSpeed;

  /// Загружает поток выбранного качества/аудиодорожки и (опционально)
  /// внешние субтитры (.ass/.srt), см. docs/architecture.md, п.4.1.
  Future<void> load(StreamLink stream);

  Future<void> play();

  Future<void> pause();

  Future<void> seekTo(Duration position);

  Future<void> setPlaybackSpeed(double speed);

  /// Переключение на другой поток без потери позиции воспроизведения —
  /// например, при смене качества или аудиодорожки на лету.
  Future<void> switchStream(StreamLink stream, {bool keepPosition = true});

  Future<void> dispose();
}
