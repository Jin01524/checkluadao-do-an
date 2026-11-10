import 'dart:convert';
import 'dart:io';

import 'package:app_checkluadao_ttnt/app/checkluadao_app.dart';
import 'package:app_checkluadao_ttnt/core/api/api_client.dart';
import 'package:app_checkluadao_ttnt/core/legacy_scan_cleanup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'upgrade deletes old history without touching other app files',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'scan_privacy_test_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final history = File('${directory.path}/scan_history_v1.json');
      final unrelated = File('${directory.path}/preferences.json');
      await history.writeAsString(
        '[{"pending":{"originalText":"old message"}}]',
      );
      await unrelated.writeAsString('keep');
      await clearLegacyScanHistory(directory: directory);
      await clearLegacyScanHistory(directory: directory);
      expect(await history.exists(), isFalse);
      expect(await unrelated.readAsString(), 'keep');
    },
  );

  testWidgets('no history and a short result starts a fresh scan', (
    tester,
  ) async {
    final requests = <http.Request>[];
    final api = ApiClient(
      httpClient: MockClient((request) async {
        if (request.method != 'POST') return http.Response('{}', 200);
        requests.add(request);
        expect(request.url.path, '/api/v2/check');
        expect(request.body, isNot(contains('name="scanSessionId"')));
        expect(request.body, isNot(contains('name="originalText"')));
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'isScam': false,
              'assessment': {
                'status': 'insufficient_context',
                'riskScore': null,
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
    await tester.pumpWidget(CheckLuaDaoApp(apiClient: api));
    await tester.pumpAndSettle();
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.destinations, hasLength(3));
    expect(find.text('Lịch sử'), findsNothing);

    Future<void> scan(String text) async {
      await tester.ensureVisible(find.byKey(const Key('scan_mode_1')));
      await tester.tap(find.byKey(const Key('scan_mode_1')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('scan_text_input')));
      await tester.enterText(find.byKey(const Key('scan_text_input')), text);
      await tester.ensureVisible(find.byKey(const Key('scan_submit')));
      await tester.tap(find.byKey(const Key('scan_submit')));
      await tester.pumpAndSettle();
    }

    await scan('Tin ngắn đầu tiên');
    expect(find.byKey(const Key('suggested_reply_highlight')), findsOneWidget);
    expect(find.byKey(const Key('sender_reply')), findsNothing);
    expect(find.text('Tôi đã gửi'), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('start_new_scan')));
    await tester.tap(find.byKey(const Key('start_new_scan')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('context_follow_up')), findsNothing);
    await scan('Đoạn hội thoại mới');
    expect(requests, hasLength(2));
    expect(requests.last.body, isNot(contains('Tin ngắn đầu tiên')));
    String? id(http.Request request) =>
        RegExp('name="clientRequestId"\\r\\n\\r\\n([^\\r]+)')
            .firstMatch(request.body)
            ?.group(1);
    expect(id(requests.first), isNotNull);
    expect(id(requests.last), isNot(id(requests.first)));
    for (final state in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();
    for (final state in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('context_follow_up')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
