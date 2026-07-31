import 'source_module.dart';

/// Реестр зарегистрированных [SourceModule] с возможностью гибкого
/// включения/отключения источников в настройках
/// (docs/documentation.md, п.3.1).
class ModuleRegistry {
  final Map<String, SourceModule> _modules = {};
  final Set<String> _disabledIds = {};

  void register(SourceModule module) {
    _modules[module.id] = module;
  }

  void unregister(String moduleId) {
    _modules.remove(moduleId);
    _disabledIds.remove(moduleId);
  }

  void setEnabled(String moduleId, {required bool enabled}) {
    if (enabled) {
      _disabledIds.remove(moduleId);
    } else {
      _disabledIds.add(moduleId);
    }
  }

  bool isEnabled(String moduleId) => !_disabledIds.contains(moduleId);

  SourceModule? operator [](String moduleId) => _modules[moduleId];

  List<SourceModule> get all => List.unmodifiable(_modules.values);

  List<SourceModule> get enabled =>
      all.where((m) => isEnabled(m.id)).toList(growable: false);
}
