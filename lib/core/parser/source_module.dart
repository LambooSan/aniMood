import '../models/content_type.dart';
import '../models/entry.dart';
import '../models/resource.dart';
import '../models/title.dart';
import 'script_engine_type.dart';

/// Результат постраничного поиска/выдачи каталога.
class SearchResult {
  const SearchResult({required this.titles, this.hasMore = false});

  final List<Title> titles;
  final bool hasMore;
}

/// Фильтры глобального поиска (docs/documentation.md, п.3.1).
class SearchFilters {
  const SearchFilters({this.contentTypes = const {}, this.page = 1});

  final Set<ContentType> contentTypes;
  final int page;
}

/// Контракт, которому должен соответствовать любий адаптер под конкретный
/// сайт-источник (docs/architecture.md, п.3 — Source Module API).
///
/// Реализации — независимые друг от друга модули: сбой одной реализации
/// не должен приводить к исключениям в других или в [ParserEngine]
/// (см. docs/architecture.md, п.8 — изоляция сбоя модуля).
abstract class SourceModule {
  /// Уникальный идентификатор источника (используется как [Title.sourceId]).
  String get id;

  /// Отображаемое имя источника, например "Anilibria".
  String get displayName;

  /// Типы контента, которые предоставляет источник.
  Set<ContentType> get supportedTypes;

  /// Версия модуля — используется для отображения в настройках и для
  /// принятия решения об обновлении при поломке парсинга.
  int get version;

  /// Среда исполнения, используемая этим модулем.
  ScriptEngineType get engineType;

  /// Признак того, что источник требует прохождения проверки
  /// Cloudflare/DDoS-Guard через системный WebView перед обычными запросами.
  bool get requiresWebViewBypass => false;

  Future<SearchResult> search(String query, SearchFilters filters);

  Future<Title> getDetails(String titleId);

  Future<List<Entry>> getEntries(String titleId);

  Future<List<Resource>> resolveEntry(String entryId);
}
