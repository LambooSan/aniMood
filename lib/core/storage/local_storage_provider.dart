import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_storage.dart';

/// Точка доступа к [LocalStorage] для экранов. Реальный экземпляр
/// ([SqfliteLocalStorage]) подставляется через `overrideWithValue` в
/// `main()` после асинхронной инициализации БД.
final Provider<LocalStorage> localStorageProvider = Provider<LocalStorage>((
  ref,
) {
  throw UnimplementedError(
    'localStorageProvider должен быть переопределён в main() — '
    'см. ProviderScope(overrides: [...])',
  );
});
