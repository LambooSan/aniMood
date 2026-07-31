import '../../models/content_type.dart';
import '../../models/entry.dart';
import '../../models/resource.dart';
import '../../models/title.dart';
import '../../network/api_client.dart';
import '../script_engine_type.dart';
import '../source_module.dart';

/// Второй реальный [SourceModule] — обращается к официальному публичному
/// API проекта Anilibria/AniLiberty (https://anilibria.top/api/docs/v1),
/// одного из источников, прямо упомянутых в docs/documentation.md. API не
/// требует ключей для чтения каталога и, в отличие от [JikanSourceModule]
/// в этом же пакете, реально хостит видео сам — эпизоды отдаются в виде
/// готовых HLS-ссылок (`hls_480`/`hls_720`/`hls_1080`), поэтому
/// [resolveEntry] здесь возвращает настоящий поток конкретной серии, а не
/// демонстрационную заглушку.
///
/// Ограничение: не у каждого релиза видео хостится самой Anilibria — для
/// части тайтлов (например, лицензированных не ими) API отдаёт
/// `external_player` (ссылку на сторонний плеер вроде Kodik) и пустой
/// список `episodes`. Такие тайтлы [getEntries] возвращает без серий —
/// разбор стороннего плеера не входит в этот модуль (это отдельный вопрос
/// соответствия ToS стороннего сайта, см. README).
class AnilibriaSourceModule implements SourceModule {
  AnilibriaSourceModule({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  static const _baseUrl = 'https://anilibria.top/api/v1';
  static const _siteUrl = 'https://anilibria.top';

  @override
  String get id => 'anilibria';

  @override
  String get displayName => 'Anilibria';

  @override
  Set<ContentType> get supportedTypes => {ContentType.video};

  @override
  int get version => 1;

  @override
  ScriptEngineType get engineType => ScriptEngineType.javascript;

  @override
  bool get requiresWebViewBypass => false;

  @override
  Future<SearchResult> search(String query, SearchFilters filters) async {
    if (filters.contentTypes.isNotEmpty &&
        !filters.contentTypes.contains(ContentType.video)) {
      return const SearchResult(titles: []);
    }

    final response = await _api.get<Map<String, dynamic>>(
      '$_baseUrl/anime/catalog/releases',
      queryParameters: {'f[search]': query, 'page': filters.page, 'limit': 20},
    );

    final data = response.data?['data'] as List<dynamic>? ?? [];
    final titles = data
        .map((json) => _titleFromJson(json as Map<String, dynamic>))
        .toList(growable: false);

    final pagination =
        (response.data?['meta'] as Map<String, dynamic>?)?['pagination']
            as Map<String, dynamic>?;
    final hasNext = (pagination?['links'] as Map<String, dynamic>?)?['next'] != null;

    return SearchResult(titles: titles, hasMore: hasNext);
  }

  @override
  Future<Title> getDetails(String titleId) async {
    final response = await _api.get<Map<String, dynamic>>(
      '$_baseUrl/anime/releases/$titleId',
    );
    return _titleFromJson(response.data!);
  }

  @override
  Future<List<Entry>> getEntries(String titleId) async {
    final response = await _api.get<Map<String, dynamic>>(
      '$_baseUrl/anime/releases/$titleId',
    );
    final episodes = response.data?['episodes'] as List<dynamic>? ?? [];

    return episodes.map((json) {
      final map = json as Map<String, dynamic>;
      final uuid = map['id'] as String;
      return Entry(
        id: '$titleId:$uuid',
        titleId: titleId,
        number: (map['ordinal'] as num?)?.toDouble() ?? 0,
        name: map['name'] as String?,
      );
    }).toList(growable: false);
  }

  @override
  Future<List<Resource>> resolveEntry(String entryId) async {
    final parts = entryId.split(':');
    if (parts.length != 2) {
      throw ArgumentError('Некорректный entryId для Anilibria: $entryId');
    }
    final titleId = parts[0];
    final episodeUuid = parts[1];

    final response = await _api.get<Map<String, dynamic>>(
      '$_baseUrl/anime/releases/$titleId',
    );
    final episodes = response.data?['episodes'] as List<dynamic>? ?? [];
    final episode = episodes
        .map((e) => e as Map<String, dynamic>)
        .firstWhere(
          (e) => e['id'] == episodeUuid,
          orElse: () => throw StateError('Серия $episodeUuid не найдена'),
        );

    const qualities = {'hls_1080': '1080p', 'hls_720': '720p', 'hls_480': '480p'};
    final streams = <StreamLink>[];
    for (final entry in qualities.entries) {
      final url = episode[entry.key] as String?;
      if (url != null) {
        streams.add(StreamLink(url: url, quality: entry.value));
      }
    }

    if (streams.isEmpty) {
      throw StateError('Для серии $episodeUuid нет доступных HLS-потоков');
    }
    return streams;
  }

  Title _titleFromJson(Map<String, dynamic> json) {
    final name = json['name'] as Map<String, dynamic>?;
    final poster = json['poster'] as Map<String, dynamic>?;
    final optimized = poster?['optimized'] as Map<String, dynamic>?;
    final posterPath = (optimized?['src'] ?? poster?['src']) as String?;
    final genres = (json['genres'] as List<dynamic>? ?? [])
        .map((g) => (g as Map<String, dynamic>)['name'] as String)
        .toList(growable: false);
    final isOngoing = json['is_ongoing'] as bool? ?? false;

    return Title(
      id: json['id'].toString(),
      sourceId: id,
      name: (name?['main'] ?? name?['english'] ?? 'Без названия') as String,
      type: ContentType.video,
      coverUrl: posterPath == null ? null : '$_siteUrl$posterPath',
      description: json['description'] as String?,
      genres: genres,
      status: isOngoing ? 'Онгоинг' : 'Завершён',
    );
  }
}
