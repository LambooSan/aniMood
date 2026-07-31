/// Ошибка одного [SourceModule], перехваченная [ParserEngine], чтобы не
/// приводить к падению остальной системы (docs/architecture.md, п.8 —
/// изоляция сбоя модуля / деградация вместо падения).
class ModuleFailure {
  const ModuleFailure({
    required this.sourceId,
    required this.error,
  });

  final String sourceId;
  final Object error;

  @override
  String toString() => 'ModuleFailure(sourceId: $sourceId, error: $error)';
}
