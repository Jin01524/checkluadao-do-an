import '../../core/models/scan_result.dart';

/// Public summary: never includes input messages, OCR, URLs or free-form AI text.
String safeScanSummary(ScanResult result, String levelLabel) {
  final score = result.confidenceScore;
  return 'CheckLuaDao: $levelLabel${score == null ? '' : ' ($score% điểm rủi ro AI)'}\n'
      'Kết quả AI chỉ mang tính hỗ trợ. Hãy xác minh qua kênh chính thức.';
}
