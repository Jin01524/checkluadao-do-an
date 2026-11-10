import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../app/app_config.dart';
import '../models/scan_result.dart';
import 'api_exception.dart';

class ScanImage {
  const ScanImage({required this.bytes, required this.name});
  final List<int> bytes;
  final String name;
}

class ApiClient {
  ApiClient({http.Client? httpClient}) : _client = httpClient ?? http.Client();

  final http.Client _client;
  String? _pendingFingerprint;
  String? _pendingRequestId;

  String _requestIdFor(String fingerprint) {
    if (_pendingFingerprint != fingerprint) {
      _pendingFingerprint = fingerprint;
      _pendingRequestId = _requestId();
    }
    return _pendingRequestId!;
  }

  void _clearRequestId(String id) {
    if (_pendingRequestId == id) {
      _pendingFingerprint = null;
      _pendingRequestId = null;
    }
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    try {
      final response = await _client
          .get(AppConfig.uri(path, query))
          .timeout(const Duration(seconds: 35));
      return _decode(response.statusCode, response.bodyBytes);
    } on TimeoutException {
      throw const ApiException('Máy chủ phản hồi quá lâu. Vui lòng thử lại.');
    } on SocketException {
      throw const ApiException(
        'Không có kết nối mạng hoặc không truy cập được máy chủ.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Không kết nối được máy chủ. Vui lòng kiểm tra mạng.',
      );
    } on FormatException {
      throw const ApiException('Địa chỉ máy chủ chưa được cấu hình đúng.');
    }
  }

  Future<ScanResult> scan({
    required String text,
    required List<ScanImage> images,
  }) async {
    final id = _requestIdFor('scan|$text|${_imagesFingerprint(images)}');
    final fields = {
      'platform': 'sms',
      'clientRequestId': id,
      if (text.trim().isNotEmpty) 'text': text.trim(),
    };
    try {
      final result = await _sendScan(
        '/api/v2/check',
        fields: fields,
        images: images,
      );
      _clearRequestId(id);
      return result;
    } on ApiException catch (error) {
      // Keep scanning available while the v2 backend is being rolled out.
      if (error.statusCode != 404) rethrow;
      final result = await _sendScan(
        '/api/check',
        fields: fields,
        images: images,
      );
      _clearRequestId(id);
      return result;
    }
  }

  Future<ScanResult> _sendScan(
    String path, {
    required Map<String, String> fields,
    required List<ScanImage> images,
  }) async {
    final request = http.MultipartRequest('POST', AppConfig.uri(path));
    request.fields.addAll(fields);
    for (final image in images) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'images',
          image.bytes,
          filename: image.name,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    try {
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 180));
      final bytes = await streamed.stream.toBytes().timeout(
        const Duration(seconds: 30),
      );
      return ScanResult.fromJson(_decode(streamed.statusCode, bytes));
    } on TimeoutException {
      // A timeout does not prove the backend did not finish the scan. Never retry automatically.
      throw const ApiException(
        'Chưa nhận được kết quả. Máy chủ có thể đã xử lý; hãy kiểm tra mạng rồi chủ động thử lại.',
      );
    } on SocketException {
      throw const ApiException(
        'Không có kết nối mạng hoặc không truy cập được máy chủ.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Kết nối bị gián đoạn. Nội dung của bạn vẫn được giữ để thử lại.',
      );
    }
  }

  Map<String, dynamic> _decode(int status, List<int> bytes) {
    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } catch (_) {
      throw ApiException(
        'Máy chủ trả dữ liệu không đọc được.',
        statusCode: status,
      );
    }
    if (decoded is! Map) {
      throw ApiException('Dữ liệu trả về không hợp lệ.', statusCode: status);
    }
    final body = Map<String, dynamic>.from(decoded);
    if (status < 200 || status >= 300) {
      final message =
          stringValue(body['error']) ?? stringValue(body['message']);
      throw ApiException(
        message ?? 'Máy chủ báo lỗi ($status).',
        statusCode: status,
      );
    }
    return body;
  }

  void close() => _client.close();
}

String _requestId() {
  final random = Random.secure();
  return List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

String _imagesFingerprint(List<ScanImage> images) => images
    .map(
      (image) =>
          '${image.name}:${image.bytes.length}:${identityHashCode(image.bytes)}',
    )
    .join('|');
