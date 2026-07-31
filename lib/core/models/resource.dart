/// Исполняемый/читаемый ресурс конкретной [Entry] — то, что фактически
/// воспроизводит соответствующий Core Engine.
///
/// Соответствует Resource из docs/architecture.md, п.3 (StreamLink /
/// PageImage / TextBlock). Sealed class: Core Engine различает вариант
/// через exhaustive switch, без приведения типов.
///
/// [toJson]/[fromJson] нужны для офлайн-кеша (docs/architecture.md, п.5) —
/// [LocalStorage] хранит ресурсы конкретной Entry сериализованными.
sealed class Resource {
  const Resource();

  Map<String, dynamic> toJson();

  static Resource fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'stream':
        return StreamLink.fromJson(json);
      case 'page':
        return PageImage.fromJson(json);
      case 'text':
        return TextBlock.fromJson(json);
      default:
        throw ArgumentError('Неизвестный тип Resource: ${json['type']}');
    }
  }
}

/// Видеопоток для Video pipeline (docs/architecture.md, п.4.1).
class StreamLink extends Resource {
  const StreamLink({
    required this.url,
    required this.quality,
    this.audioTrack,
    this.subtitleUrl,
  });

  factory StreamLink.fromJson(Map<String, dynamic> json) {
    return StreamLink(
      url: json['url'] as String,
      quality: json['quality'] as String,
      audioTrack: json['audioTrack'] as String?,
      subtitleUrl: json['subtitleUrl'] as String?,
    );
  }

  final String url;

  /// Например: "360p", "720p", "1080p", "4K".
  final String quality;
  final String? audioTrack;
  final String? subtitleUrl;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'stream',
    'url': url,
    'quality': quality,
    'audioTrack': audioTrack,
    'subtitleUrl': subtitleUrl,
  };
}

/// Страница манги/манхвы для Reader pipeline (docs/architecture.md, п.4.2).
class PageImage extends Resource {
  const PageImage({required this.url, required this.pageNumber});

  factory PageImage.fromJson(Map<String, dynamic> json) {
    return PageImage(
      url: json['url'] as String,
      pageNumber: json['pageNumber'] as int,
    );
  }

  final String url;
  final int pageNumber;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'page',
    'url': url,
    'pageNumber': pageNumber,
  };
}

/// Текстовый блок ранобэ — для чтения либо для Text TTS Engine.
class TextBlock extends Resource {
  const TextBlock({required this.content});

  factory TextBlock.fromJson(Map<String, dynamic> json) {
    return TextBlock(content: json['content'] as String);
  }

  final String content;

  @override
  Map<String, dynamic> toJson() => {'type': 'text', 'content': content};
}
