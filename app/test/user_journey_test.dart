import 'dart:convert';

import 'package:app_checkluadao_ttnt/app/checkluadao_app.dart';
import 'package:app_checkluadao_ttnt/core/api/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('kho mẫu đổi chủ đề, gõ từ khóa và xóa tìm kiếm', (tester) async {
    final searches = <String>[];
    final api = ApiClient(
      httpClient: MockClient((request) async {
        if (request.url.path == '/api/stats') {
          return _json({'totalScans': 0, 'warnedScans': 0});
        }
        if (request.url.path == '/api/templates') {
          searches.add(request.url.queryParameters['search'] ?? '');
          return _json({'data': <Object>[], 'hasMore': false});
        }
        return _json({'error': 'Không tìm thấy fixture.'}, status: 404);
      }),
    );
    addTearDown(api.close);

    await tester.pumpWidget(CheckLuaDaoApp(apiClient: api));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kho mẫu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ngân hàng'));
    await tester.pumpAndSettle();
    expect(searches.last, 'ngân hàng');
    await tester.enterText(find.byKey(const Key('template_search')), 'OTP');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(searches.last, 'OTP');
    await tester.tap(find.byTooltip('Xóa tìm kiếm'));
    await tester.pumpAndSettle();
    expect(searches.last, '');
  });

  testWidgets('quét văn bản rồi tra cứu nhiều trang mẫu và mở chi tiết', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var scanRequests = 0;
    final first = _template('mau-1', 'Mẫu ngân hàng giả');
    final second = {
      ..._template('mau-2', 'Mẫu việc làm giả'),
      'is_approved': false,
    };
    final api = ApiClient(
      httpClient: MockClient((request) async {
        if (request.url.path == '/api/check') {
          scanRequests++;
          return _json({
            'isScam': true,
            'confidenceScore': 91,
            'analysis': 'Mẫu kiểm thử có yêu cầu cung cấp OTP.',
          });
        }
        if (request.url.path == '/api/templates') {
          final offset = request.url.queryParameters['offset'];
          return offset == '0'
              ? _json({
                  'data': [first],
                  'hasMore': true,
                })
              : _json({
                  'data': [first, second],
                  'hasMore': false,
                });
        }
        if (request.url.path == '/api/templates/mau-2') {
          return _json({
            'data': {
              ...second,
              'analysis': 'Mẫu minh họa yêu cầu chuyển tiền trước.',
            },
          });
        }
        return _json({'error': 'Không tìm thấy fixture.'}, status: 404);
      }),
    );
    addTearDown(api.close);

    await tester.pumpWidget(CheckLuaDaoApp(apiClient: api));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dán văn bản'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('scan_text_input')),
      'Mẫu giả lập cần kiểm tra',
    );
    await tester.ensureVisible(find.byKey(const Key('scan_submit')));
    await tester.tap(find.byKey(const Key('scan_submit')));
    await tester.pumpAndSettle();
    expect(scanRequests, 1);
    expect(find.text('Nguy cơ rất cao'), findsOneWidget);

    await tester.tap(find.text('Kho mẫu'));
    await tester.pumpAndSettle();
    expect(find.text('Mẫu ngân hàng giả'), findsOneWidget);
    await tester.ensureVisible(find.text('Xem thêm'));
    await tester.tap(find.text('Xem thêm'));
    await tester.pumpAndSettle();
    expect(find.text('Mẫu ngân hàng giả'), findsOneWidget);
    expect(find.text('Mẫu việc làm giả'), findsOneWidget);
    expect(find.text('Chưa được kiểm duyệt'), findsOneWidget);

    await tester.ensureVisible(find.text('Mẫu việc làm giả'));
    await tester.tap(find.text('Mẫu việc làm giả'));
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết mẫu tin nhắn'), findsOneWidget);
    expect(find.text('Chưa được kiểm duyệt'), findsOneWidget);
    expect(
      find.text('Mẫu minh họa yêu cầu chuyển tiền trước.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('kho mẫu và chi tiết không tràn ở màn nhỏ với chữ lớn', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final item = _template('mau-nho', 'Mẫu ngân hàng giả lập');
    final api = ApiClient(
      httpClient: MockClient((request) async {
        if (request.url.path == '/api/templates') {
          return _json({
            'data': [item],
            'hasMore': false,
          });
        }
        if (request.url.path == '/api/templates/mau-nho') {
          return _json({
            'data': {
              ...item,
              'analysis': 'Nội dung giả lập để kiểm tra bố cục chữ lớn.',
              'warning_points': ['Yêu cầu cung cấp OTP'],
            },
          });
        }
        return _json({'error': 'Không tìm thấy fixture.'}, status: 404);
      }),
    );
    addTearDown(api.close);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
        child: CheckLuaDaoApp(apiClient: api),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kho mẫu'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Mẫu ngân hàng giả lập'),
      250,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('template_page')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Mẫu ngân hàng giả lập'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Nội dung giả lập để kiểm tra bố cục chữ lớn.'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('Nội dung giả lập để kiểm tra bố cục chữ lớn.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('lỗi tải kho mẫu hiện trong vùng nhìn thấy để thử lại', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var requests = 0;
    final api = ApiClient(
      httpClient: MockClient((request) async {
        if (request.url.path == '/api/stats') {
          return _json({'totalScans': 0, 'warnedScans': 0});
        }
        requests++;
        return requests == 1
            ? _json({'error': 'Máy chủ kho mẫu tạm bận.'}, status: 503)
            : _json({
                'data': [_template('mau-thu-lai', 'Mẫu sau khi thử lại')],
                'hasMore': false,
              });
      }),
    );
    addTearDown(api.close);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
        child: CheckLuaDaoApp(apiClient: api),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kho mẫu'));
    await tester.pumpAndSettle();

    final error = find.text('Máy chủ kho mẫu tạm bận.');
    expect(error, findsOneWidget);
    expect(tester.getTopLeft(error).dy, greaterThan(0));
    expect(tester.getBottomLeft(error).dy, lessThan(540));
    expect(find.text('Thử lại'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(requests, 2);
    expect(find.text('Máy chủ kho mẫu tạm bận.'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Mẫu sau khi thử lại'),
      250,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('template_page')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Mẫu sau khi thử lại'), findsOneWidget);
  });
}

Map<String, Object> _template(String id, String title) => {
  'id': id,
  'title': title,
  'platform': 'sms',
  'scam_type': 'Giả mạo',
  'analysis': 'Mẫu minh họa.',
  'is_approved': true,
  'confidence_score': 91,
};

http.Response _json(Object body, {int status = 200}) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
