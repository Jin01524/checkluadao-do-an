import 'package:app_checkluadao_ttnt/core/models/scam_template.dart';
import 'package:app_checkluadao_ttnt/core/models/scan_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_checkluadao_ttnt/core/models/system_stats.dart';

void main() {
  test('thống kê không tính tỷ lệ khi chưa có lượt quét', () {
    final stats = SystemStats.fromJson({'totalScans': 0, 'warnedScans': 0});
    expect(stats.warningPercent, 0);
    expect(
      () => SystemStats.fromJson({'totalScans': 1, 'warnedScans': 2}),
      throwsFormatException,
    );
  });

  test('điểm rủi ro chuẩn hóa nhưng không bịa điểm thiếu', () {
    expect(parseRiskScore(null), isNull);
    expect(parseRiskScore('0.95'), 95);
    expect(parseRiskScore(1), 1);
    expect(parseRiskScore(150), 100);
    expect(parseRiskScore(-5), 0);
  });

  test('đọc kết quả quét với trường tùy chọn vắng mặt', () {
    final result = ScanResult.fromJson({
      'isScam': false,
      'analysis': 'Chưa thấy dấu hiệu chiếm đoạt.',
    });
    expect(result.isScam, isFalse);
    expect(result.confidenceScore, isNull);
    expect(result.warningPoints, isEmpty);
  });

  test('đọc trạng thái lưu và ba phân tích từ kết quả quét', () {
    final result = ScanResult.fromJson({
      'isScam': true,
      'analysis': 'Kết luận',
      'savedTemplateId': 'sample-id',
      'templateSaveStatus': 'saved',
      'multiAgentDebate': {
        'threatHunterAnalysis': 'Rủi ro',
        'auditorDefense': 'An toàn',
        'arbiterVerdict': 'Kết luận',
      },
    });
    expect(result.savedTemplateId, 'sample-id');
    expect(result.templateSaveStatus, 'saved');
    expect(result.multiAgentDebate?.isComplete, isTrue);
  });

  test('mẫu đọc được JSONB dưới dạng chuỗi hoặc mảng', () {
    final template = ScamTemplate.fromJson({
      'id': 'demo',
      'title': 'Mẫu',
      'is_approved': true,
      'warning_points': '["Yêu cầu OTP"]',
      'messages_json': [
        {'sender': 'scammer', 'text': 'Gửi OTP'},
      ],
    });
    expect(template.warningPoints, ['Yêu cầu OTP']);
    expect(template.messages.single.text, 'Gửi OTP');
  });

  test('mẫu mới đọc ba phân tích JSONB, mẫu cũ vẫn dùng analysis', () {
    final current = ScamTemplate.fromJson({
      'id': 'new',
      'analysis': 'Kết luận',
      'multi_agent_debate': {
        'threatHunterAnalysis': 'Nhận định rủi ro',
        'auditorDefense': 'Phản biện an toàn',
        'arbiterVerdict': 'Kết luận',
      },
    });
    final legacy = ScamTemplate.fromJson({
      'id': 'old',
      'analysis': 'Một phân tích',
    });
    expect(current.multiAgentDebate?.isComplete, isTrue);
    expect(current.multiAgentDebate?.arbiterVerdict, 'Kết luận');
    expect(legacy.multiAgentDebate, isNull);
    expect(legacy.analysis, 'Một phân tích');
  });

  test('mẫu an toàn không được gắn nhãn rủi ro', () {
    final template = ScamTemplate.fromJson({
      'id': 'safe',
      'scam_type': 'Tin nhắn an toàn / Bình thường',
      'confidence_score': 95,
      'is_approved': true,
    });
    expect(template.isSafe, isTrue);
    expect(template.confidenceScore, 95);
  });
}
