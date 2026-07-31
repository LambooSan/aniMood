import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../core/engines/impl/package_video_player_engine.dart';
import '../../core/models/resource.dart';
import '../../core/parser/parser_provider.dart';

/// Экран видеовоспроизведения (docs/architecture.md, п.4.1 — Video
/// pipeline): подключён к реальному [PackageVideoPlayerEngine] поверх
/// `media_kit`, а поток получает через реальный `ParserEngine.resolveEntry`
/// у [sourceId]. Жесты яркости/громкости и D-Pad-навигация — TODO.
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key, required this.sourceId, required this.entryId});

  final String sourceId;
  final String entryId;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  final PackageVideoPlayerEngine _engine = PackageVideoPlayerEngine();
  bool _loading = true;
  Object? _error;

  static const List<double> _speeds = [1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final parserEngine = ref.read(parserEngineProvider);
      final resources = await parserEngine.resolveEntry(
        widget.sourceId,
        widget.entryId,
      );
      final stream = resources.whereType<StreamLink>().firstOrNull;
      if (stream == null) {
        throw StateError('Источник не вернул видеопоток для этой серии');
      }
      await _engine.load(stream);
      await _engine.play();
    } catch (error) {
      _error = error;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(
          'Не удалось загрузить поток: $_error',
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: GestureDetector(
            // TODO: жесты яркости/громкости
            onTap: () {
              _engine.player.state.playing ? _engine.pause() : _engine.play();
            },
            child: Video(controller: _engine.controller),
          ),
        ),
        StreamBuilder<bool>(
          stream: _engine.player.stream.playing,
          initialData: _engine.player.state.playing,
          builder: (context, _) => StreamBuilder<Duration>(
            stream: _engine.player.stream.position,
            initialData: _engine.position,
            builder: (context, positionSnapshot) => _Controls(
              position: positionSnapshot.data ?? Duration.zero,
              duration: _engine.duration,
              speed: _engine.playbackSpeed,
              speeds: _speeds,
              onSeek: (position) => _engine.seekTo(position),
              onSpeedChanged: (speed) => setState(() {
                _engine.setPlaybackSpeed(speed);
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.position,
    required this.duration,
    required this.speed,
    required this.speeds,
    required this.onSeek,
    required this.onSpeedChanged,
  });

  final Duration position;
  final Duration duration;
  final double speed;
  final List<double> speeds;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<double> onSpeedChanged;

  @override
  Widget build(BuildContext context) {
    final maxMs = duration.inMilliseconds > 0 ? duration.inMilliseconds : 1;

    return Column(
      children: [
        Slider(
          value: position.inMilliseconds.clamp(0, maxMs).toDouble(),
          max: maxMs.toDouble(),
          onChanged: (ms) => onSeek(Duration(milliseconds: ms.round())),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_formatDuration(position)} / ${_formatDuration(duration)}',
                style: const TextStyle(color: Colors.white),
              ),
              DropdownButton<double>(
                value: speed,
                dropdownColor: Colors.black87,
                style: const TextStyle(color: Colors.white),
                items: speeds
                    .map(
                      (s) => DropdownMenuItem(value: s, child: Text('${s}x')),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) onSpeedChanged(value);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final minutes = two(d.inMinutes.remainder(60));
    final seconds = two(d.inSeconds.remainder(60));
    return '${two(d.inHours)}:$minutes:$seconds';
  }
}
