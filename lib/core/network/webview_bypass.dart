/// Результат прохождения проверки Cloudflare/DDoS-Guard через системный
/// WebView — cookies и User-Agent, которые нужно приложить к последующим
/// обычным HTTP-запросам того же источника (docs/architecture.md, п.2).
class WebViewBypassResult {
  const WebViewBypassResult({required this.cookies, required this.userAgent});

  final Map<String, String> cookies;
  final String userAgent;
}

/// Сервис прохождения анти-бот проверок для источников, у которых
/// [SourceModule.requiresWebViewBypass] == true.
///
/// Конкретная реализация рендерит [url] в headless/скрытом системном
/// WebView (пакет `webview_flutter`), дожидается прохождения JS-проверки
/// и извлекает cookies — здесь описан только контракт.
abstract class WebViewBypassService {
  Future<WebViewBypassResult> resolve(String url);
}
