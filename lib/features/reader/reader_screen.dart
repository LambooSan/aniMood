import 'package:flutter/material.dart';

/// Экран чтения манги/манхвы/ранобэ (docs/architecture.md, п.4.2 — Reader
/// pipeline): постраничная подгрузка с прогревом соседних страниц, либо
/// передача текста в Text TTS.
///
/// Подключается к [ReaderEngine]/[TtsEngine] (TODO) — здесь только каркас.
class ReaderScreen extends StatelessWidget {
  const ReaderScreen({super.key, required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Ридер: $entryId\nTODO: ReaderEngine.loadPages(...)'),
      ),
    );
  }
}
