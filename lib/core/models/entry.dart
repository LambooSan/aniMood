/// Единица контента внутри тайтла: серия (видео/дорама) либо глава
/// (манга/манхва/ранобэ).
///
/// Соответствует Entry из docs/architecture.md, п.3.
class Entry {
  const Entry({
    required this.id,
    required this.titleId,
    required this.number,
    this.name,
  });

  final String id;
  final String titleId;

  /// Порядковый номер серии/главы (может быть дробным, напр. 12.5).
  final double number;
  final String? name;
}
