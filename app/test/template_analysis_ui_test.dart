import 'dart:convert';

import 'package:app_checkluadao_ttnt/core/api/api_client.dart';
import 'package:app_checkluadao_ttnt/core/models/scan_result.dart';
import 'package:app_checkluadao_ttnt/features/scan/scan_result_card.dart';
import 'package:app_checkluadao_ttnt/features/templates/template_detail_page.dart';
import 'package:app_checkluadao_ttnt/features/templates/template_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('kết quả quét hiện trạng thái lưu và ba phân tích', (
    tester,
  ) async {
    final result = ScanResult.fromJson({
      'isScam': true,
      'confidenceScore': 80,
      'analysis': 'Kết luận cuối',
      'savedTemplateId': 'new-id',
      'templateSaveStatus': 'saved',
      'multiAgentDebate': {
        'threatHunterAnalysis': 'Có dấu hiệu đòi OTP.',
        'auditorDefense': 'Không thấy kênh chính thức.',
        'arbiterVerdict': 'Kết luận cuối',
      },
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: ScanResultCard(result: result)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Đã lưu mẫu vào kho cảnh báo'), findsOneWidget);
    expect(find.text('AI 1 · Phân tích rủi ro'), findsOneWidget);
    expect(find.text('AI 2 · Phân tích an toàn'), findsOneWidget);
    expect(find.text('AI 3 · Kết luận'), findsOneWidget);
    expect(find.text('Phân tích của AI'), findsNothing);
  });

  testWidgets('chi tiết mẫu mới hiện ba phần AI', (tester) async {
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final client = ApiClient(
      httpClient: MockClient((_) async {
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'data': {
                'id': 'new',
                'title': 'Mẫu mới',
                'analysis': 'Kết luận cuối',
                'is_approved': false,
                'multi_agent_debate': {
                  'threatHunterAnalysis': 'Có yêu cầu OTP.',
                  'auditorDefense': 'Không có nguồn chính thức.',
                  'arbiterVerdict': 'Kết luận cuối',
                },
              },
            }),
          ),
          200,
        );
      }),
    );
    addTearDown(client.close);
    await tester.pumpWidget(
      MaterialApp(
        home: TemplateDetailPage(
          repository: TemplateRepository(client),
          id: 'new',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mẫu mới'), findsOneWidget);
    expect(find.text('AI 1 · Phân tích rủi ro'), findsOneWidget);
    expect(find.text('AI 2 · Phân tích an toàn'), findsOneWidget);
    expect(find.text('AI 3 · Kết luận'), findsOneWidget);
  });
}
