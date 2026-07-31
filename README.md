# AniMood

Кроссплатформенный каркас (Flutter/Dart) приложения-агрегатора аниме,
дорам, манги, манхвы и ранобэ — под Android, Android TV и десктоп
(AniMood MAX: Windows/Linux/macOS). Реализует архитектуру, описанную в
[docs/architecture.md](docs/architecture.md) и
[docs/documentation.md](docs/documentation.md).

## Статус

| Компонент | Статус |
|---|---|
| `VideoPlayerEngine` (media_kit) | Рабочая реализация |
| `LocalStorage` (sqflite) | Рабочая реализация |
| `JikanSourceModule` (метаданные, MyAnimeList) | Рабочая реализация |
| `AnilibriaSourceModule` (видео + метаданные) | Рабочая реализация |
| `ReaderEngine`, `TtsEngine` | Контракт (интерфейс), реализации нет |
| `BackupService` | Контракт, реализации нет |
| `TrackerProvider` (Shikimori/AniList/MAL/MyDramaList) | Контракт + заглушки, без OAuth |
| `WebViewBypassService` | Контракт, реализации нет |
| Субтитры (.ass/.srt) | Не реализовано |

## Требования

- Flutter SDK ≥ 3.19 (Dart ≥ 3.3)
- Для сборки под Linux: `libmpv-dev` (используется `media_kit` для
  видеовоспроизведения)

```bash
sudo apt-get install libmpv-dev
```

## Установка и запуск

```bash
# Нативные platform-папки (android/, linux/) уже сгенерированы в этом
# репозитории. Для остальных платформ — при необходимости:
flutter create --project-name animood --org com.animood .

flutter pub get

flutter run                 # подключённое устройство/эмулятор
flutter run -d linux        # десктоп (нужен libmpv-dev)
```

## Структура проекта

```
lib/
  core/
    models/       # Title, Entry, Resource — единая нормализованная модель
    parser/       # ParserEngine, SourceModule (контракт), ModuleRegistry
      impl/       #   JikanSourceModule, AnilibriaSourceModule
    engines/      # VideoPlayerEngine (контракт), ReaderEngine, TtsEngine
      impl/       #   PackageVideoPlayerEngine — реализация на media_kit
    storage/      # LocalStorage (контракт), BackupService (контракт)
      impl/       #   SqfliteLocalStorage — реализация на sqflite
    tracking/     # TrackingService, TrackerProvider + заглушки провайдеров
    network/      # ApiClient (proxy/SOCKS5), WebViewBypassService (контракт)
  features/       # Экраны: home, search, player, reader, library, settings
  platform/       # AdaptiveScaffold — навигация mobile/TV/desktop
  app_router.dart # go_router: навигационный shell + полноэкранные роуты
  main.dart
```

Каждый файл ссылается в докстринге на соответствующий раздел
`docs/architecture.md`.

## Технические решения

### Видео: media_kit вместо video_player

`video_player` не имеет реализации для Linux/Windows-десктопа
(federated-плагины покрывают только Android/iOS/Web). Видеодвижок
реализован на [`media_kit`](https://pub.dev/packages/media_kit)
(обёртка над libmpv), который поддерживает Android/iOS/Linux/Windows/macOS
единым кодом.

Реализация: `lib/core/engines/impl/package_video_player_engine.dart`.

### Хранилище: sqflite + sqflite_common_ffi

`sqflite` также не имеет реализации под Linux/Windows. На десктопе
`SqfliteLocalStorage.open()` переключает `databaseFactory` на
`sqflite_common_ffi` (sqlite3 через FFI); на Android/iOS используется
штатный `sqflite`. `LocalStorage` доступен экранам через `flutter_riverpod`
(`local_storage_provider.dart`).

Реализация: `lib/core/storage/impl/sqflite_local_storage.dart`.

### Source Modules

**`JikanSourceModule`** — источник метаданных на публичном API
[Jikan](https://jikan.moe) (неофициальная REST-обёртка над MyAnimeList,
без ключей). Реализует `search`/`getDetails`/`getEntries` на реальных
данных; `resolveEntry` возвращает демонстрационный видеопоток — у Jikan
нет собственного видеохостинга.

> Живые (не кешируемые на стороне Jikan) эндпоинты — `/anime?q=` и
> `/anime/{id}/episodes` — возвращают HTTP 504, если запрос содержит
> заголовок `Accept-Encoding` (с любым значением). `dart:io`'s
> `HttpClient` всегда отправляет `Accept-Encoding: gzip`, независимо от
> `autoUncompress`. Поэтому модуль использует сырой `dart:io HttpClient`
> с явным `request.headers.removeAll(HttpHeaders.acceptEncodingHeader)`,
> а не общий `ApiClient` (dio), который не даёт доступа к заголовкам на
> этом уровне.

**`AnilibriaSourceModule`** — источник видео на официальном публичном API
[Anilibria/AniLiberty](https://anilibria.top/api/docs/v1) (один из
источников, названных в docs/documentation.md; открытая экосистема
сторонних клиентов, ключ не нужен). В отличие от Jikan, Anilibria хостит
видео сама: эпизоды содержат абсолютные HLS-ссылки трёх качеств
(`hls_480`/`hls_720`/`hls_1080`), поэтому `resolveEntry` возвращает
реальный поток конкретной серии.

> Часть каталога (тайтлы, лицензированные не Anilibria) отдаётся через
> `external_player` — ссылку на сторонний плеер (например, Kodik) без
> списка эпизодов/HLS. Для таких тайтлов `getEntries` возвращает пустой
> список; разбор стороннего плеера не входит в этот модуль.

Оба модуля зарегистрированы в `lib/core/parser/parser_provider.dart` и
подключены в `SearchScreen` (сквозной поиск) и `PlayerScreen`
(`resolveEntry`).

## Проверка

```bash
flutter analyze
flutter test
flutter build linux --debug
```

Дополнительно вручную проверено (headless, через Xvfb):

- Воспроизведение видео через `PackageVideoPlayerEngine`/`media_kit` — на
  демонстрационном потоке и на реальном HLS-потоке Anilibria.
- Запись/чтение через `SqfliteLocalStorage` (история, закладки, кеш
  ресурсов) на sqlite3/FFI.
- Сквозной сетевой цикл `search → getEntries → resolveEntry` для обоих
  Source Modules через `ParserEngine`.
- Навигация `SearchScreen → тап по результату → PlayerScreen`
  (`/player/:sourceId/:entryId`) виджет-тестом с симуляцией ввода и тапа.

## Дальнейшие шаги

- Дополнительные Source Modules под источники из docs/documentation.md
  (Kodik, MangaLib и др.) — требуют отдельной проверки API/ToS каждого
  сайта.
- Реализация `WebViewBypassService` (`webview_flutter`) для источников с
  защитой Cloudflare/DDoS-Guard.
- OAuth-аутентификация в заглушках `lib/core/tracking/providers/*`.
- Рендер .ass/.srt субтитров поверх `Video` (`media_kit` не рендерит
  субтитры сам — см. TODO в `package_video_player_engine.dart`).
- Download manager для офлайн-кеша: `cacheResources` сейчас сохраняет
  только метаданные/URL ресурса, не скачивает сами файлы.
