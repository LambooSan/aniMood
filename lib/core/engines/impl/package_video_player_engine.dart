import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../models/resource.dart';
import '../playback_state.dart';
import '../video_player_engine.dart';

/// Реализация [VideoPlayerEngine] поверх `media_kit` (libmpv) —
/// единственный кроссплатформенный вариант, реально работающий на всех
/// целевых платформах AniMood (docs/architecture.md, п.9: Android, Android
/// TV, AniMood MAX на Windows/Linux/macOS). Пакет `video_player` не
/// подходил: у него нет реализации для Linux/Windows-десктопа.
///
/// Помимо контракта [VideoPlayerEngine], предоставляет [controller]
/// ([VideoController]) — его использует UI (`PlayerScreen`) для рендера
/// кадра через виджет `Video` из `media_kit_video`.
///
/// [PlaybackState.error] здесь не выставляется автоматически: mpv-поток
/// `player.stream.error` — это, по сути, лог диагностических сообщений
/// (в т.ч. некритичные предупреждения о недоступном аппаратном ускорении,
/// после которых воспроизведение продолжается на программном рендере), а
/// не надёжный признак фатального сбоя. Реальные ошибки загрузки потока
/// проявляются как исключение из [load] — его обрабатывает вызывающий код.
///
/// Подключение .ass/.srt субтитров как отдельного оверлея — TODO.
class PackageVideoPlayerEngine implements VideoPlayerEngine {
  PackageVideoPlayerEngine() : player = Player() {
    controller = VideoController(player);
  }

  final Player player;
  late final VideoController controller;

  bool _wasPlaying = false;

  @override
  PlaybackState get state {
    final playerState = player.state;
    if (playerState.duration == Duration.zero && !playerState.playing) {
      return PlaybackState.idle;
    }
    if (playerState.buffering) return PlaybackState.buffering;
    return playerState.playing ? PlaybackState.playing : PlaybackState.paused;
  }

  @override
  Duration get position => player.state.position;

  @override
  Duration get duration => player.state.duration;

  @override
  double get playbackSpeed => player.state.rate;

  @override
  Future<void> load(StreamLink stream) async {
    await player.open(Media(stream.url), play: false);
  }

  @override
  Future<void> play() async {
    _wasPlaying = true;
    await player.play();
  }

  @override
  Future<void> pause() async {
    _wasPlaying = false;
    await player.pause();
  }

  @override
  Future<void> seekTo(Duration position) => player.seek(position);

  @override
  Future<void> setPlaybackSpeed(double speed) => player.setRate(speed);

  @override
  Future<void> switchStream(
    StreamLink stream, {
    bool keepPosition = true,
  }) async {
    final previousPosition = keepPosition ? position : Duration.zero;
    final resumePlaying = _wasPlaying;

    await load(stream);
    if (previousPosition > Duration.zero) {
      await seekTo(previousPosition);
    }
    if (resumePlaying) {
      await play();
    }
  }

  @override
  Future<void> dispose() async {
    await player.dispose();
  }
}
