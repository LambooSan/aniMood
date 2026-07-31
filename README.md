# AniMood — каркас приложения

Кроссплатформенный каркас (Flutter/Dart) под Android, Android TV и десктоп
(AniMood MAX), реализующий структуру, описанную в
[docs/architecture.md](docs/architecture.md) и
[docs/documentation.md](docs/documentation.md).

Видеовоспроизведение (`VideoPlayerEngine`), локальное хранилище
(`LocalStorage`) и первый источник данных (`JikanSourceModule`) — уже
рабочие реализации, не заглушки: проверены полным циклом сборки и запуска
(см. "Что уже проверено"). Остальное — контракты (абстрактные классы),
нормализованные модели данных и UI-навигация под три платформы.

## Структура

```
lib/
  core/
    models/       # Title, Entry, Resource — единая нормализованная модель
    parser/       # ParserEngine, SourceModule (контракт), ModuleRegistry;
                  #   JikanSourceModule (impl/) — рабочий источник данных
                  #   на публичном API Jikan (MyAnimeList); parser_provider.dart
    engines/      # ReaderEngine, TtsEngine (контракты);
                  # VideoPlayerEngine — контракт + рабочая реализация
                  #   на media_kit в engines/impl/
    storage/      # LocalStorage (контракт) + рабочая реализация на sqflite
                  #   в storage/impl/; BackupService (контракт);
                  #   local_storage_provider.dart — riverpod Provider
    tracking/     # TrackingService, TrackerProvider + заглушки провайдеров
    network/      # ApiClient (proxy/SOCKS5), WebViewBypassService (контракт)
  features/       # Экраны: home, search, player, reader, library, settings
  platform/       # AdaptiveScaffold — навигация mobile/TV/desktop
  app_router.dart # go_router: навигационный shell + полноэкранные роуты
  main.dart
```

Каждый файл ссылается в докстринге на соответствующий раздел
`docs/architecture.md`, чтобы не расходиться с ним по терминологии.

## Видеодвижок: media_kit, не video_player

Пакет `video_player` **не имеет реализации для Linux/Windows-десктопа**
(federated-плагины есть только под Android/iOS/Web) — это выяснилось при
попытке реально запустить `PlayerScreen`: `VideoPlayerPlatform.init()`
кидал `UnimplementedError` на Linux. Поскольку AniMood MAX должен работать
на десктопе (docs/architecture.md, п.9), видеодвижок переведён на
[`media_kit`](https://pub.dev/packages/media_kit) (обёртка над libmpv) —
он реально поддерживает Android/iOS/Linux/Windows/macOS одним и тем же
кодом. Реализация — `lib/core/engines/impl/package_video_player_engine.dart`.

**Системная зависимость для сборки под Linux:** нужен `libmpv-dev` (иначе
CMake упадёт на этапе линковки `media_kit_video_plugin`):

```bash
sudo apt-get install libmpv-dev
```

## Хранилище: sqflite + sqflite_common_ffi

`sqflite` тоже не имеет реализации под Linux/Windows — та же ситуация, что
и с `video_player`. На десктопе `SqfliteLocalStorage.open()`
(`lib/core/storage/impl/sqflite_local_storage.dart`) переключает
`databaseFactory` на `sqflite_common_ffi` (sqlite3 через FFI), на
Android/iOS остаётся штатный `sqflite`. `LocalStorage` пробрасывается в
экраны через `flutter_riverpod` (`local_storage_provider.dart`,
переопределяется в `main()` после асинхронного открытия БД).

## Первый реальный Source Module: Jikan (MyAnimeList)

`JikanSourceModule` (`lib/core/parser/impl/jikan_source_module.dart`) ходит
в живой публичный API [Jikan](https://jikan.moe) — неофициальную
REST-обёртку над MyAnimeList, без ключей/авторизации. Реальны
`search`/`getDetails`/`getEntries`; `resolveEntry` возвращает тот же
демо-ролик, что и раньше — у Jikan просто нет видеохостинга, это честная
заглушка именно на месте видео. Подключён в `SearchScreen` (реальный
поиск) и `PlayerScreen` (реальный `resolveEntry`) через
`parser_provider.dart` (riverpod).

**Найденный и исправленный баг Jikan.** Живые (не кешируемые на их
стороне) эндпоинты — `/anime?q=` и `/anime/{id}/episodes` — стабильно
отдают 504, если в запросе присутствует заголовок `Accept-Encoding` (с
любым значением, даже `identity`) — похоже на баг пережатия ответа на их
стороне при проксировании MyAnimeList. `dart:io`'s `HttpClient` всегда
добавляет `Accept-Encoding: gzip`, независимо от `autoUncompress`; убрать
его можно только явным `request.headers.removeAll(...)` на самом запросе.
Поэтому модуль ходит через сырой `dart:io HttpClient`, а не через общий
`ApiClient` (dio), который такого доступа не даёт. Реальный live-тест
через `ParserEngine` подтвердил: `getDetails`/`getEntries`/`resolveEntry`
получают настоящие данные (проверено на Fullmetal Alchemist: Brotherhood,
64 серии); `search` в моменте проверки упирался в отдельный, независимый
от нас сбой live-текстового поиска на стороне самого MyAnimeList — и
`ParserEngine.search` корректно изолировал этот сбой, не уронив
приложение (docs/architecture.md, п.8).

## Запуск

```bash
# 1. Установить Flutter SDK: https://docs.flutter.dev/get-started/install
flutter doctor

# 2. Сгенерировать нативные platform-папки (android/ios/windows/linux/macos) —
#    уже сделано для linux/ и android/ в этом репозитории; для остальных
#    платформ выполнить по необходимости:
cd /opt/aniMood
flutter create --project-name animood --org com.animood .

# 3. Установить зависимости
flutter pub get

# 4. Запустить
flutter run                 # на подключённом устройстве/эмуляторе
flutter run -d linux        # десктоп-таргет (нужен libmpv-dev, см. выше)
```

## Что уже проверено

Собрано и запущено в headless-окружении (Xvfb, без физического дисплея):

* `flutter analyze` — 0 замечаний.
* `flutter test` — smoke-тест приложения проходит.
* `flutter build linux --debug` — собирается и линкуется.
* Реальное воспроизведение видео через `PackageVideoPlayerEngine`
  (media_kit/libmpv) на тестовом потоке — подтверждено продвижением
  позиции воспроизведения и изменением размера видеотекстуры под реальное
  разрешение ролика.
* `SqfliteLocalStorage` — реальная запись/чтение истории, закладок и
  кеша ресурсов (с сериализацией `StreamLink`/`PageImage`/`TextBlock` и
  подсчётом размера кеша) через sqlite3/FFI; `HomeScreen`/`LibraryScreen`
  читают эти данные вживую, не заглушки.
* `JikanSourceModule` — реальные сетевые вызовы через `ParserEngine`
  (getDetails/getEntries/resolveEntry на живых данных MyAnimeList), плюс
  `SearchScreen` → тап по результату → `getEntries` → навигация на
  `/player/:sourceId/:entryId` — проверено виджет-тестом с симуляцией
  ввода и тапа.

## Что дальше

* Реализовать второй Source Module под реальный видео/манга-хостинг
  (Anilibria/Kodik/MangaLib и т.п. из docs/documentation.md) — это
  отдельный вопрос соответствия их ToS, не решённый в рамках Jikan-модуля.
* Подставить конкретную реализацию `WebViewBypassService`
  (`webview_flutter`).
* Реализовать OAuth-аутентификацию в заглушках `lib/core/tracking/providers/*`.
* Подключить рендер .ass/.srt субтитров поверх `Video` (media_kit не
  рендерит субтитры сам — см. TODO в `package_video_player_engine.dart`).
* Реальный download manager для офлайн-кеша (сейчас `cacheResources`
  сохраняет только метаданные/URL, не скачивает сами файлы).
