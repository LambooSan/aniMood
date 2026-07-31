import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'impl/anilibria_source_module.dart';
import 'impl/jikan_source_module.dart';
import 'module_registry.dart';
import 'parser_engine.dart';

/// Реестр модулей и движок парсинга, доступные экранам через riverpod.
/// Регистрация модулей — единственное место, которое нужно менять при
/// добавлении новых источников (docs/architecture.md, п.3).
final Provider<ModuleRegistry> moduleRegistryProvider = Provider<ModuleRegistry>((
  ref,
) {
  return ModuleRegistry()
    ..register(JikanSourceModule())
    ..register(AnilibriaSourceModule());
});

final Provider<ParserEngine> parserEngineProvider = Provider<ParserEngine>((
  ref,
) {
  return ParserEngine(ref.watch(moduleRegistryProvider));
});
