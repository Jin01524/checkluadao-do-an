import 'dart:convert';

import 'package:app_checkluadao_ttnt/app/checkluadao_app.dart';
import 'package:app_checkluadao_ttnt/core/api/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('thống kê dùng lượt quét thật và cập nhật sau khi quét', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var scanned = false;
    final api = ApiClient(
      httpClient: MockClient((request) async {
        if (request.url.path == '/api/stats') {
          return http.Response(
            jsonEncode({
              'totalScans': scanned ? 4 : 3,
              'warnedScans': scanned ? 2 : 1,
              'maxConfidence': 90,
            }),
            200,
          );
        }
        if (request.url.path == '/api/v2/check') {
          scanned = true;
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'isScam': true,
                'analysis': 'Mẫu giả lập có rủi ro.',
              }),
            ),
            200,
          );
        }
        return http.Response('{}', 200);
      }),
    );
    addTearDown(api.close);

    await tester.pumpWidget(CheckLuaDaoApp(apiClient: api));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('THỐNG KÊ LƯỢT QUÉT')).dy,
      lessThan(tester.getTopLeft(find.text('Kiểm tra tin nhắn nghi vấn')).dy),
    );
    expect(find.text('33,3%'), findsOneWidget);
    expect(find.text('1/3 lượt có cảnh báo rủi ro'), findsOneWidget);
    await tester.tap(find.text('Dán văn bản'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('scan_text_input')),
      'Tin giả lập',
    );
    await tester.ensureVisible(find.byKey(const Key('scan_submit')));
    await tester.tap(find.byKey(const Key('scan_submit')));
    await tester.pumpAndSettle();
    expect(scanned, isTrue);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('4'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('2/4 lượt có cảnh báo rủi ro'), findsOneWidget);
  });

  testWidgets('thẻ thống kê không tràn trên màn nhỏ với chữ lớn', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = ApiClient(
      httpClient: MockClient((request) async {
        if (request.url.path == '/api/stats') {
          return http.Response(
            jsonEncode({'totalScans': 12345, 'warnedScans': 6789}),
            200,
          );
        }
        return http.Response('{}', 200);
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
    await tester.ensureVisible(
      find.text('6.789/12.345 lượt có cảnh báo rủi ro'),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('12.345'), findsOneWidget);
  });

  testWidgets('màn quét không tràn bố cục ở điện thoại nhỏ', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = ApiClient(
      httpClient: MockClient((request) async => http.Response('{}', 200)),
    );
    addTearDown(api.close);

    await tester.pumpWidget(CheckLuaDaoApp(apiClient: api));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(const Key('scan_submit')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('ba chế độ quét vẫn đọc được khi phóng chữ', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = ApiClient(
      httpClient: MockClient((request) async => http.Response('{}', 200)),
    );
    addTearDown(api.close);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
        child: CheckLuaDaoApp(apiClient: api),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Quét màn hình'), findsWidgets);
    expect(
      MediaQuery.textScalerOf(tester.element(find.text('Quét màn hình').first))
          .scale(10),
      18,
    );
    final tabHeight = tester
        .getSize(find.byKey(const Key('scan_mode_0')))
        .height;
    expect(
      tester.getSize(find.byKey(const Key('scan_mode_1'))).height,
      tabHeight,
    );
    expect(
      tester.getSize(find.byKey(const Key('scan_mode_2'))).height,
      tabHeight,
    );
  });

  testWidgets('màn quét chặn yêu cầu không có nội dung', (tester) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = ApiClient(
      httpClient: MockClient((request) async {
        if (request.url.path == '/api/templates') {
          return http.Response(jsonEncode({'data': <Object>[]}), 200);
        }
        return http.Response('{}', 200);
      }),
    );
    addTearDown(api.close);

    await tester.pumpWidget(CheckLuaDaoApp(apiClient: api));
    await tester.pumpAndSettle();
    expect(find.text('Kiểm tra tin nhắn nghi vấn'), findsOneWidget);
    expect(find.text('Kho mẫu'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('scan_submit')));
    await tester.tap(find.byKey(const Key('scan_submit')));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(
        'Lỗi quét: Hãy nhập nội dung hoặc chọn ít nhất một ảnh.',
      ),
      findsOneWidget,
    );
    final error = find.text('Hãy nhập nội dung hoặc chọn ít nhất một ảnh.');
    expect(tester.getBottomLeft(error).dy, lessThan(1200));
    await tester.drag(
      find.byKey(const Key('scan_page')),
      const Offset(0, -250),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Hãy nhập nội dung hoặc chọn ít nhất một ảnh.'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('màn quét giữ bản nháp sau lỗi máy chủ', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = ApiClient(
      httpClient: MockClient((request) async {
        if (request.url.path == '/api/v2/check') {
          return http.Response.bytes(
            utf8.encode('{"error":"Máy chủ tạm bận"}'),
            503,
          );
        }
        return http.Response('{}', 200);
      }),
    );
    addTearDown(api.close);

    await tester.pumpWidget(CheckLuaDaoApp(apiClient: api));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dán văn bản'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('scan_text_input')),
      'Tin giả lập để kiểm thử',
    );
    await tester.ensureVisible(find.byKey(const Key('scan_submit')));
    await tester.tap(find.byKey(const Key('scan_submit')));
    await tester.pumpAndSettle();

    final input = tester.widget<TextField>(
      find.byKey(const Key('scan_text_input')),
    );
    expect(input.controller!.text, 'Tin giả lập để kiểm thử');
    await tester.drag(
      find.byKey(const Key('scan_page')),
      const Offset(0, -350),
    );
    await tester.pumpAndSettle();
    expect(find.text('Máy chủ tạm bận'), findsOneWidget);
  });

  testWidgets('quét xong tự cuộn để kết quả xuất hiện trên màn hình', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = ApiClient(
      httpClient: MockClient((request) async {
        if (request.url.path == '/api/v2/check') {
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'isScam': false,
                'confidenceScore': 5,
                'analysis': 'Nội dung giả lập an toàn.',
              }),
            ),
            200,
          );
        }
        return http.Response('{}', 200);
      }),
    );
    addTearDown(api.close);

    await tester.pumpWidget(CheckLuaDaoApp(apiClient: api));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dán văn bản'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('scan_text_input')),
      'Nội dung giả lập',
    );
    await tester.ensureVisible(find.byKey(const Key('scan_submit')));
    await tester.tap(find.byKey(const Key('scan_submit')));
    await tester.pumpAndSettle();

    final result = find.byKey(const Key('scan_result'));
    expect(result, findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Chưa thấy dấu hiệu lừa đảo')).dy,
      inInclusiveRange(0, 950),
    );
    expect(find.text('Nội dung giả lập an toàn.'), findsOneWidget);
    final riskSummary = find.bySemanticsLabel(RegExp('Đánh giá rủi ro:'));
    expect(riskSummary, findsOneWidget);
    expect(tester.getSemantics(riskSummary).label, contains('5 trên 100 điểm'));
    semantics.dispose();
  });

  testWidgets('báo cáo quét không tràn ở màn nhỏ khi phóng chữ', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var scanRequests = 0;
    final api = ApiClient(
      httpClient: MockClient((request) async {
        if (request.url.path == '/api/v2/check') {
          scanRequests++;
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'isScam': true,
                'confidenceScore': 100,
                'analysis': 'Mẫu giả lập có dấu hiệu yêu cầu mã OTP.',
              }),
            ),
            200,
          );
        }
        return http.Response('{}', 200);
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
    await tester.ensureVisible(find.text('Dán văn bản'));
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
    expect(find.byKey(const Key('scan_result')), findsOneWidget);
    expect(find.text('Nguy cơ rất cao'), findsOneWidget);
  });
}
