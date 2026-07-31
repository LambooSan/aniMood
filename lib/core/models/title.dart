import 'content_type.dart';

/// Тайтл — единица каталога (аниме/дорама/манга/манхва/ранобэ),
/// нормализованная из ответа Source Module.
///
/// [sourceId] и [id] однозначно определяют тайтл в рамках конкретного
/// источника; один и тот же тайтл в разных источниках может иметь разные
/// [id] — сопоставление между источниками не выполняется на этом уровне.
class Title {
  const Title({
    required this.id,
    required this.sourceId,
    required this.name,
    required this.type,
    this.coverUrl,
    this.description,
    this.genres = const [],
    this.status,
  });

  final String id;
  final String sourceId;
  final String name;
  final ContentType type;
  final String? coverUrl;
  final String? description;
  final List<String> genres;
  final String? status;
}
