import 'package:app_checkluadao_ttnt/core/models/scan_result.dart';
import 'package:app_checkluadao_ttnt/features/scan/safe_scan_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shared summary excludes raw and free-form sensitive content', () {
    const secret = 'MA_OTP_RIENG_TU_654321';
    const result = ScanResult(
      isScam: true,
      confidenceScore: 91,
      analysis: 'Kẻ gian yêu cầu $secret',
      ocrExtractedText: secret,
      messages: [ScanMessage(sender: 'user', text: secret)],
      extractedUrls: ['https://example.invalid/private/$secret'],
    );

    final summary = safeScanSummary(result, 'Nguy cơ cao');
    expect(summary, contains('Nguy cơ cao'));
    expect(summary, contains('91%'));
    expect(summary, isNot(contains(secret)));
    expect(summary, isNot(contains('example.invalid')));
  });
}
