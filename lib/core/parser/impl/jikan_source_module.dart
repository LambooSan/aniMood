import 'dart:convert';
import 'dart:io';

import '../../models/content_type.dart';
import '../../models/entry.dart';
import '../../models/resource.dart';
import '../../models/title.dart';
import '../script_engine_type.dart';
import '../source_module.dart';

/// Первый реальный (не заглушка) [SourceModule] — обращается к живому
/// публичному API Jikan (https://jikan.moe), неофициальной REST-обёртке
/// над MyAnimeList. Не требует ключей/авторизации.
///
/// Ограничение: Jikan отдаёт только метаданные (тайтлы, синопсис, список
/// серий) — реального видеохостинга у него нет. Поэтому [resolveEntry]
/// возвращает тот же публичный демонстрационный ролик, что уже
/// используется в `PlayerScreen`, а не поток конкретной серии — честная
/// заглушка именно и только на месте видео, при полностью реальных
/// search/getDetails/getEntries.
///
/// **Обходной путь для бага Jikan.** Живые (не кешированные) эндпоинты —
/// `/anime?q=` (поиск) и `/anime/{id}/episodes` — стабильно отдают 504,
/// если запрос содержит заголовок `Accept-Encoding` (любое значение, даже
/// `identity`), похоже, из-за бага пережатия ответа на их стороне при
/// проксировании MyAnimeList. Кешируемые эндпоинты (`/anime/{id}/full`)
/// этой проблемой не страдают. `dart:io`'s `HttpClient` всегда добавляет
/// `Accept-Encoding: gzip`, независимо от `autoUncompress` — единственный
/// способ его не отправлять — вызвать
/// `request.headers.removeAll(HttpHeaders.acceptEncodingHeader)` на самом
/// запросе. Поэтому этот модуль ходит напрямую через `dart:io`
/// `HttpClient`, а не через общий `ApiClient` (dio) — тот не даёт доступа
/// к сырому `HttpClientRequest`, чтобы убрать заголовок целиком.
///
/// [engineType] формально помечен как [ScriptEngineType.javascript], хотя
/// по факту модуль — обычный REST/JSON-клиент на чистом Dart без
/// исполнения стороннего скрипта. Три движка из docs/architecture.md
/// (regex/js/lua) рассчитаны на парсинг HTML сайтов-скрейперов; для
/// готового JSON API такая категоризация не совсем применима — это
/// наблюдение, а не что-то, что нужно было решать в рамках этого модуля.
class JikanSourceModule implements SourceModule {
  JikanSourceModule({HttpClient? httpClient})
    : _client = httpClient ?? HttpClient();

  final HttpClient _client;

  static const _baseUrl = 'https://api.jikan.moe/v4';

  // Jikan не хостит видео — см. докстринг класса.
  static const _demoStream = StreamLink(
    url: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    quality: '720p',
  );

  @override
  String get id => 'jikan';

  @override
  String get displayName => 'Jikan (MyAnimeList)';

  @override
  Set<ContentType> get supportedTypes => {ContentType.video};

  @override
  int get version => 1;

  @override
  ScriptEngineType get engineType => ScriptEngineType.javascript;

  @override
  bool get requiresWebViewBypass => false;

  void dispose() => _client.close();

  @override
  Future<SearchResult> search(String query, SearchFilters filters) async {
    if (filters.contentTypes.isNotEmpty &&
        !filters.contentTypes.contains(ContentType.video)) {
      return const SearchResult(titles: []);
    }

    final json = await _getJson('/anime', {
      'q': query,
      'page': filters.page,
    });

    final data = json['data'] as List<dynamic>? ?? [];
    final titles = data
        .map((item) => _titleFromJson(item as Map<String, dynamic>))
        .toList(growable: false);

    final pagination = json['pagination'] as Map<String, dynamic>?;
    final hasNext = pagination?['has_next_page'] as bool? ?? false;

    return SearchResult(titles: titles, hasMore: hasNext);
  }

  @override
  Future<Title> getDetails(String titleId) async {
    final json = await _getJson('/anime/$titleId/full', {});
    return _titleFromJson(json['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<Entry>> getEntries(String titleId) async {
    final json = await _getJson('/anime/$titleId/episodes', {});
    final data = json['data'] as List<dynamic>? ?? [];

    return data.map((item) {
      final map = item as Map<String, dynamic>;
      final malId = map['mal_id'] as int;
      return Entry(
        id: '$titleId:$malId',
        titleId: titleId,
        number: malId.toDouble(),
        name: map['title'] as String?,
      );
    }).toList(growable: false);
  }

  @override
  Future<List<Resource>> resolveEntry(String entryId) async {
    return const [_demoStream];
  }

  Future<Map<String, dynamic>> _getJson(
    String path,
    Map<String, dynamic> query,
  ) async {
    final stringQuery = query.map((k, v) => MapEntry(k, v.toString()));
    final uri = Uri.parse(
      '$_baseUrl$path',
    ).replace(queryParameters: stringQuery.isEmpty ? null : stringQuery);

    final request = await _client.getUrl(uri);
    // См. докстринг класса: без этого живые эндпоинты Jikan отдают 504.
    request.headers.removeAll(HttpHeaders.acceptEncodingHeader);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode >= 400) {
      throw HttpException('Jikan HTTP ${response.statusCode}: $body', uri: uri);
    }
    return jsonDecode(body) as Map<String, dynamic>;
  }

  Title _titleFromJson(Map<String, dynamic> json) {
    final images = json['images'] as Map<String, dynamic>?;
    final jpg = images?['jpg'] as Map<String, dynamic>?;
    final genres = (json['genres'] as List<dynamic>? ?? [])
        .map((g) => (g as Map<String, dynamic>)['name'] as String)
        .toList(growable: false);

    return Title(
      id: json['mal_id'].toString(),
      sourceId: id,
      name:
          (json['title'] ?? json['title_english'] ?? 'Без названия')
              as String,
      type: ContentType.video,
      coverUrl: jpg?['image_url'] as String?,
      description: json['synopsis'] as String?,
      genres: genres,
      status: json['status'] as String?,
    );
  }
}
