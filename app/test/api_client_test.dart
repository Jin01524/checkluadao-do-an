import 'dart:convert';

import 'package:app_checkluadao_ttnt/core/api/api_client.dart';
import 'package:app_checkluadao_ttnt/core/api/api_exception.dart';
import 'package:app_checkluadao_ttnt/features/templates/template_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'scan surfaces backend 503 without submitting a second request',
    () async {
      var requests = 0;
      final api = ApiClient(
        httpClient: MockClient((request) async {
          requests++;
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({'error': 'Hệ thống AI tạm thời không khả dụng'}),
            ),
            503,
          );
        }),
      );
      addTearDown(api.close);

      await expectLater(
        api.scan(text: 'Tin nhắn giả lập', images: const []),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 503)),
      );
      expect(requests, 1);
    },
  );

  test('scan sends multipart field names and parses AI response', () async {
    final api = ApiClient(
      httpClient: MockClient((request) async {
        expect(request.url.path, '/api/v2/check');
        expect(request.method, 'POST');
        expect(
          request.headers['content-type'],
          contains('multipart/form-data'),
        );
        expect(request.body, contains('name="text"'));
        expect(request.body, contains('name="platform"'));
        expect(request.body, contains('name="clientRequestId"'));
        expect(request.body, contains('name="images"'));
        expect(request.body, contains('image/jpeg'));
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'isScam': true,
              'confidenceScore': 92,
              'analysis': 'Có yêu cầu cung cấp OTP.',
            }),
          ),
          200,
        );
      }),
    );
    addTearDown(api.close);

    final result = await api.scan(
      text: 'Gửi OTP',
      images: const [
        ScanImage(bytes: [1, 2, 3], name: 'scan_1.jpg'),
      ],
    );
    expect(result.isScam, isTrue);
    expect(result.confidenceScore, 92);
  });

  test('short result is followed by an independent new scan', () async {
    final paths = <String>[];
    final api = ApiClient(
      httpClient: MockClient((request) async {
        paths.add(request.url.path);
        expect(request.url.path, '/api/v2/check');
        expect(request.body, isNot(contains('name="scanSessionId"')));
        expect(request.body, isNot(contains('name="originalText"')));
        if (paths.length == 2) {
          expect(request.body, isNot(contains('Chào bạn')));
          expect(request.body, contains('Tôi là nhân viên'));
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'isScam': true,
                'assessment': {
                  'status': 'high_risk',
                  'riskScore': 87,
                  'reason': 'Có yêu cầu OTP',
                },
                'changedBecause': 'Phản hồi mới yêu cầu OTP',
              }),
            ),
            200,
          );
        }
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'isScam': false,
              'confidenceScore': null,
              'assessment': {
                'status': 'insufficient_context',
                'riskScore': null,
                'reason': 'Tin quá ngắn',
              },
              'suggestedReply': {
                'text': 'Bạn muốn trao đổi về việc gì?',
                'round': 1,
              },
            }),
          ),
          200,
        );
      }),
    );
    addTearDown(api.close);

    final first = await api.scan(text: 'Chào bạn', images: const []);
    expect(first.assessmentStatus, 'insufficient_context');
    expect(first.confidenceScore, isNull);
    expect(first.suggestedReply?.text, 'Bạn muốn trao đổi về việc gì?');
    expect(first.scanSessionId, isNull);
    final updated = await api.scan(
      text: 'Tôi là nhân viên, gửi OTP cho tôi',
      images: const [],
    );
    expect(updated.assessmentStatus, 'high_risk');
    expect(updated.confidenceScore, 87);
    expect(paths, ['/api/v2/check', '/api/v2/check']);
  });

  test('scan falls back to legacy endpoint only when v2 is absent', () async {
    final paths = <String>[];
    final api = ApiClient(
      httpClient: MockClient((request) async {
        paths.add(request.url.path);
        if (request.url.path == '/api/v2/check') {
          return http.Response.bytes(
            utf8.encode('{"error":"Route not found"}'),
            404,
          );
        }
        return http.Response.bytes(
          utf8.encode('{"isScam":false,"confidenceScore":12}'),
          200,
        );
      }),
    );
    addTearDown(api.close);
    final result = await api.scan(text: 'Tin nhắn cũ', images: const []);
    expect(result.confidenceScore, 12);
    expect(paths, ['/api/v2/check', '/api/check']);
  });

  test('manual retry reuses request id for unchanged scan content', () async {
    final ids = <String>[];
    var attempts = 0;
    final api = ApiClient(
      httpClient: MockClient((request) async {
        attempts++;
        final match = RegExp('name="clientRequestId"\\r\\n\\r\\n([^\\r\\n]+)')
            .firstMatch(request.body);
        ids.add(match!.group(1)!);
        if (attempts == 1) {
          return http.Response.bytes(utf8.encode('{"error":"Tạm bận"}'), 503);
        }
        return http.Response.bytes(
          utf8.encode('{"isScam":false,"confidenceScore":7}'),
          200,
        );
      }),
    );
    addTearDown(api.close);
    await expectLater(
      api.scan(text: 'Cùng một tin', images: const []),
      throwsA(isA<ApiException>()),
    );
    await api.scan(text: 'Cùng một tin', images: const []);
    expect(ids, hasLength(2));
    expect(ids[0], ids[1]);
  });

  test('template repository presents both review states', () async {
    final api = ApiClient(
      httpClient: MockClient((request) async {
        expect(request.url.queryParameters.containsKey('approved'), isFalse);
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'hasMore': false,
              'data': [
                {
                  'id': 'approved',
                  'title': 'Mẫu công khai',
                  'is_approved': true,
                },
                {
                  'id': 'pending',
                  'title': 'Mẫu chưa duyệt',
                  'is_approved': false,
                },
              ],
            }),
          ),
          200,
        );
      }),
    );
    addTearDown(api.close);

    final list = await TemplateRepository(api).list();
    expect(list.items.map((item) => item.id), ['approved', 'pending']);
    expect(list.items.map((item) => item.isApproved), [true, false]);
    expect(list.nextOffset, 2);
    expect(list.hasMore, isFalse);
  });
}
