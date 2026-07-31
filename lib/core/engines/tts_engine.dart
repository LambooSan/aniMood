import '../models/resource.dart';
import 'playback_state.dart';

/// Core Engine голосового воспроизведения текста ранобэ
/// (docs/architecture.md, п.4.2 — Text TTS).
abstract class TtsEngine {
  PlaybackState get state;

  double get rate;

  Future<void> speak(TextBlock text);

  Future<void> pause();

  Future<void> resume();

  Future<void> stop();

  Future<void> setRate(double rate);
}
