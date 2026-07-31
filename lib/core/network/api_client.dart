import 'dart:io' show HttpClient;

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'proxy_config.dart';

/// Единый HTTP-клиент для всех Source Modules — прямые HTTPS-запросы к
/// источникам, без промежуточного сервера AniMood
/// (docs/architecture.md, п.7).
///
/// Оборачивает `dio`, чтобы модули не настраивали сеть самостоятельно и
/// подчинялись единой конфигурации прокси.
class ApiClient {
  ApiClient({ProxyConfig proxy = const ProxyConfig()}) : _dio = Dio() {
    applyProxy(proxy);
  }

  final Dio _dio;

  Dio get raw => _dio;

  /// Применяет системный Proxy/SOCKS5 либо снимает его (прямое соединение).
  void applyProxy(ProxyConfig proxy) {
    final adapter = _dio.httpClientAdapter;
    if (adapter is! IOHttpClientAdapter) return;

    adapter.createHttpClient = () {
      final client = HttpClient();
      if (!proxy.isDirect && proxy.host != null && proxy.port != null) {
        final scheme = proxy.type == ProxyType.socks5 ? 'SOCKS5' : 'PROXY';
        client.findProxy = (_) => '$scheme ${proxy.host}:${proxy.port}';
      }
      return client;
    };
  }

  Future<Response<T>> get<T>(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) {
    return _dio.get<T>(
      url,
      queryParameters: queryParameters,
      options: headers == null ? null : Options(headers: headers),
    );
  }
}
