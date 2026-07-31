import 'package:flutter/material.dart';

/// Настройки: включение/отключение источников (docs/documentation.md,
/// п.3.1), сеть/прокси (п.4.1), хранилище/кеш (п.5.2), аккаунты трекеров
/// (п.5.3), импорт/экспорт бекапа.
///
/// Каждый раздел подключается к соответствующему сервису ядра (TODO) —
/// здесь только каркас навигации по разделам.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        _SettingsSection(
          icon: Icons.source,
          title: 'Источники',
          subtitle: 'Включение/отключение каталогов — TODO: ModuleRegistry',
        ),
        _SettingsSection(
          icon: Icons.wifi_tethering,
          title: 'Сеть',
          subtitle: 'Proxy / SOCKS5 — TODO: ApiClient.applyProxy',
        ),
        _SettingsSection(
          icon: Icons.storage,
          title: 'Хранилище',
          subtitle: 'Кеш серий/страниц — TODO: LocalStorage.cacheSizeBytes',
        ),
        _SettingsSection(
          icon: Icons.sync,
          title: 'Трекинг',
          subtitle: 'Shikimori / AniList / MAL / MyDramaList — TODO: TrackingService',
        ),
        _SettingsSection(
          icon: Icons.import_export,
          title: 'Бекап',
          subtitle: 'Импорт/экспорт настроек и БД — TODO: BackupService',
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () {},
    );
  }
}
