import '../models/entry.dart';
import '../models/resource.dart';
import '../models/title.dart';
import 'module_failure.dart';
import 'module_registry.dart';
import 'source_module.dart';

/// Единая точка входа для всех обращений к внешним источникам
/// (docs/architecture.md, п.1–2 — Parser Engine).
///
/// Выбирает подходящий [SourceModule] (или несколько — при сквозном
/// поиске), исполняет его и возвращает нормализованный результат.
/// Ошибка отдельного модуля перехватывается и не прерывает остальные
/// вызовы — см. docs/architecture.md, п.8.
class ParserEngine {
  ParserEngine(this.registry);

  final ModuleRegistry registry;

  /// Сквозной поиск по всем включённым источникам, соответствующим
  /// [filters] (docs/documentation.md, п.3.1 — Глобальный поиск).
  ///
  /// Возвращает объединённый список найденных тайтлов; сбои отдельных
  /// модулей собираются в [ModuleSearchOutcome.failures] и не прерывают
  /// остальной поиск.
  Future<ModuleSearchOutcome> search(
    String query,
    SearchFilters filters,
  ) async {
    final modules = registry.enabled
        .where(
          (m) =>
              filters.contentTypes.isEmpty ||
              m.supportedTypes.intersection(filters.contentTypes).isNotEmpty,
        )
        .toList(growable: false);

    final titles = <Title>[];
    final failures = <ModuleFailure>[];

    for (final module in modules) {
      try {
        final result = await module.search(query, filters);
        titles.addAll(result.titles);
      } catch (error) {
        failures.add(ModuleFailure(sourceId: module.id, error: error));
      }
    }

    return ModuleSearchOutcome(titles: titles, failures: failures);
  }

  Future<Title> getDetails(String sourceId, String titleId) {
    return _requireModule(sourceId).getDetails(titleId);
  }

  Future<List<Entry>> getEntries(String sourceId, String titleId) {
    return _requireModule(sourceId).getEntries(titleId);
  }

  Future<List<Resource>> resolveEntry(String sourceId, String entryId) {
    return _requireModule(sourceId).resolveEntry(entryId);
  }

  SourceModule _requireModule(String sourceId) {
    final module = registry[sourceId];
    if (module == null || !registry.isEnabled(sourceId)) {
      throw StateError('Source module "$sourceId" недоступен или отключён');
    }
    return module;
  }
}

/// Результат сквозного поиска: успешные тайтлы плюс изолированные сбои
/// отдельных источников.
class ModuleSearchOutcome {
  const ModuleSearchOutcome({required this.titles, required this.failures});

  final List<Title> titles;
  final List<ModuleFailure> failures;
}
