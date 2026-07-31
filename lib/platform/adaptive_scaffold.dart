import 'package:flutter/material.dart';

/// Единая точка входа для навигации, адаптирующаяся под три целевые
/// платформы (docs/architecture.md, п.9):
/// * узкий экран (Android, touch) — нижняя панель [NavigationBar];
/// * широкий экран (Android TV, AniMood MAX) — боковая [NavigationRail],
///   удобная для фокусной навигации D-Pad/клавиатурой.
///
/// Порог ширины — стандартный material-брейкпоинт компакт/расширенного
/// layout.
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.body,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AdaptiveDestination> destinations;
  final Widget body;

  static const double _wideBreakpoint = 600;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              destinations: destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: Icon(d.icon),
                      label: Text(d.label),
                    ),
                  )
                  .toList(growable: false),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations
            .map(
              (d) => NavigationDestination(icon: Icon(d.icon), label: d.label),
            )
            .toList(growable: false),
      ),
    );
  }
}

class AdaptiveDestination {
  const AdaptiveDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
