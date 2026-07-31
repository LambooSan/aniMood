import 'dart:typed_data';

/// Импорт/экспорт настроек и базы данных (docs/documentation.md, п.3.3 —
/// "Кастомизация и Бекап").
abstract class BackupService {
  /// Сериализует историю, закладки и настройки в переносимый файл бекапа.
  Future<Uint8List> exportBackup();

  /// Восстанавливает состояние из ранее экспортированного бекапа.
  Future<void> importBackup(Uint8List data);
}
