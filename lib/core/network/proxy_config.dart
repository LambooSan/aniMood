/// Настройки сетевого прокси, применяемые ко всем запросам Source Modules
/// (docs/architecture.md, п.7 — поддержка системного Proxy/SOCKS5).
///
/// AniMood не содержит встроенных обходов блокировок — при [ProxyType.none]
/// запросы идут напрямую; иначе используется прокси, настроенный
/// пользователем в "Настройки -> Сеть".
class ProxyConfig {
  const ProxyConfig({this.type = ProxyType.none, this.host, this.port});

  final ProxyType type;
  final String? host;
  final int? port;

  bool get isDirect => type == ProxyType.none;
}

enum ProxyType { none, http, socks5 }
