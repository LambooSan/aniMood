import 'package:flutter/material.dart' hide Title;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/content_type.dart';
import '../../core/models/title.dart';
import '../../core/parser/parser_provider.dart';
import '../../core/parser/source_module.dart';

/// Сквозной поиск по всем включённым источникам с фильтрацией по типу
/// контента (docs/documentation.md, п.3.1 — Глобальный поиск).
///
/// Обращается к реальному `ParserEngine.search` через [parserEngineProvider].
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final Set<ContentType> _selectedTypes = {};

  bool _loading = false;
  List<Title> _results = const [];
  List<String> _failedSources = const [];
  String? _openingEntryFor;

  Future<void> _runSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _loading = true);

    final engine = ref.read(parserEngineProvider);
    final outcome = await engine.search(
      query,
      SearchFilters(contentTypes: _selectedTypes),
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      _results = outcome.titles;
      _failedSources = outcome.failures.map((f) => f.sourceId).toList();
    });
  }

  Future<void> _openTitle(Title title) async {
    setState(() => _openingEntryFor = title.id);
    try {
      final engine = ref.read(parserEngineProvider);
      final entries = await engine.getEntries(title.sourceId, title.id);
      if (!mounted) return;
      if (entries.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('У тайтла нет доступных серий')));
        return;
      }
      context.go('/player/${title.sourceId}/${entries.first.id}');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Не удалось открыть тайтл: $error')));
    } finally {
      if (mounted) setState(() => _openingEntryFor = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Поиск по всем каталогам…',
              border: OutlineInputBorder(),
            ),
            onSubmitted: _runSearch,
          ),
        ),
        Wrap(
          spacing: 8,
          children: ContentType.values.map((type) {
            final selected = _selectedTypes.contains(type);
            return FilterChip(
              label: Text(type.name),
              selected: selected,
              onSelected: (value) {
                setState(() {
                  value ? _selectedTypes.add(type) : _selectedTypes.remove(type);
                });
              },
            );
          }).toList(growable: false),
        ),
        if (_failedSources.isNotEmpty)
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.errorContainer,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              'Источники недоступны: ${_failedSources.join(', ')}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        Expanded(child: _buildResults()),
      ],
    );
  }

  Widget _buildResults() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_results.isEmpty) {
      return const Center(child: Text('Результаты появятся здесь'));
    }
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final title = _results[index];
        final isOpening = _openingEntryFor == title.id;
        return ListTile(
          leading: title.coverUrl != null
              ? Image.network(
                  title.coverUrl!,
                  width: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image),
                )
              : const Icon(Icons.movie),
          title: Text(title.name),
          subtitle: Text(
            title.genres.isNotEmpty ? title.genres.join(', ') : title.sourceId,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: isOpening
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: isOpening ? null : () => _openTitle(title),
        );
      },
    );
  }
}
