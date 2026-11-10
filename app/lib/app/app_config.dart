import 'package:flutter/foundation.dart';

class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://check-lua-dao-backend.onrender.com',
  );
  // Set true for release only after the hardened backend is deployed and verified.
  static const backendPrivacyReady = bool.fromEnvironment(
    'BACKEND_PRIVACY_READY',
    defaultValue: false,
  );

  static Uri uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse(apiBaseUrl);
    if (base.host.isEmpty || (kReleaseMode && base.scheme != 'https')) {
      throw const FormatException(
        'Địa chỉ API chưa hợp lệ hoặc chưa dùng HTTPS.',
      );
    }
    return base.replace(
      path: '${base.path.replaceFirst(RegExp(r'/$'), '')}$path',
      queryParameters: query,
    );
  }
}
