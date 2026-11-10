import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/models/scan_result.dart';
import 'safe_scan_summary.dart';

class ScanResultCard extends StatelessWidget {
  const ScanResultCard({super.key, required this.result, this.headerKey});
  final ScanResult result;
  final Key? headerKey;

  @override
  Widget build(BuildContext context) {
    final score = result.confidenceScore;
    final level = _level(result);
    final theme = Theme.of(context);
    return Card(
      key: const Key('scan_result'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'BÁO CÁO KIỂM TRA',
              style: theme.textTheme.labelMedium?.copyWith(
                color: const Color(0xFF0037B0),
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Semantics(
              label:
                  'Đánh giá rủi ro: ${level.label}, '
                  '${score == null ? 'chưa có điểm' : '$score trên 100 điểm'}',
              liveRegion: true,
              excludeSemantics: true,
              child: Container(
                key: headerKey,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: level.color.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.zero,
                  border: Border(
                    left: BorderSide(color: level.color, width: 4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          result.isScam
                              ? Icons.warning_amber_rounded
                              : Icons.verified_user_outlined,
                          color: level.color,
                          size: 34,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ĐÁNH GIÁ RỦI RO',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: level.color,
                                ),
                              ),
                              Text(
                                level.label,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: level.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (score != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '$score/100',
                          textAlign: TextAlign.end,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: level.color,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (score != null) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: score / 100,
                minHeight: 7,
                color: level.color,
                backgroundColor: const Color(0xFFDCE9FF),
              ),
            ],
            if (result.isChatScreenshot &&
                !result.isScam &&
                score != null &&
                score < 40 &&
                result.assessmentStatus != 'insufficient_context') ...[
              const SizedBox(height: 14),
              Container(
                key: const Key('scan_recheck_notice'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF5FF),
                  border: Border.all(color: const Color(0xFFBED4FF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LƯU Ý KHI CÓ TIN NHẮN MỚI',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF0037B0),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Đánh giá này dựa trên nội dung hiện có. Nếu xuất hiện tin nhắn mới có dấu hiệu đáng nghi, bạn có thể quét lại toàn bộ cuộc trò chuyện để kiểm tra.',
                    ),
                  ],
                ),
              ),
            ],
            if (result.templateSaveStatus != null &&
                result.templateSaveStatus != 'not_applicable') ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Card(
                  color: result.templateSaveStatus == 'saved'
                      ? const Color(0xFFE6F5EC)
                      : const Color(0xFFFFF2D9),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      result.templateSaveStatus == 'saved'
                          ? (result.isScam || (score ?? 0) >= 40)
                                ? 'Đã lưu mẫu vào kho cảnh báo, trạng thái chưa kiểm duyệt.'
                                : 'Đã lưu mẫu an toàn để đối chiếu trong hệ thống.'
                          : result.templateSaveStatus == 'incomplete_analysis'
                          ? 'Đã có kết quả quét nhưng chưa lưu mẫu: AI thiếu một trong ba phần phân tích.'
                          : result.templateSaveStatus == 'deferred_review'
                          ? 'Phát hiện dấu hiệu nhạy cảm nhưng điểm AI chưa thống nhất. Chưa lưu mẫu để tránh kết luận sai.'
                          : result.templateSaveStatus ==
                                'deferred_insufficient_context'
                          ? 'Chưa đủ ngữ cảnh nên mẫu chưa được lưu vào kho.'
                          : 'Đã có kết quả quét nhưng chưa lưu được mẫu. Hãy thử lại sau.',
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (result.changedBecause != null) ...[
              Text(result.changedBecause!, style: theme.textTheme.bodySmall),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Kết quả kiểm tra',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (!result.isChatScreenshot)
              const Text(
                'Ảnh chưa có nội dung tin nhắn nhận diện được. Hãy thử ảnh rõ hơn hoặc nhập văn bản.',
              ),
            if (result.scamType != null) _field('Hình thức', result.scamType!),
            if (result.attackTarget != null)
              _field('Mục tiêu', result.attackTarget!),
            if (result.exfiltrationVector != 'none')
              _field(
                'Kênh chiếm đoạt',
                _vectorLabel(result.exfiltrationVector),
              ),
            if (result.warningPoints.isNotEmpty)
              _list(
                'Dấu hiệu cần chú ý',
                result.warningPoints,
                Icons.report_outlined,
              ),
            if (result.recommendations.isNotEmpty)
              _list(
                'Nên làm gì',
                result.recommendations,
                Icons.check_circle_outline,
              ),
            if (result.multiAgentDebate?.isComplete != true &&
                result.analysis.isNotEmpty)
              _section('Phân tích của AI', result.analysis),
            if (result.extractedUrls.isNotEmpty)
              _list(
                'URL được phát hiện (không tự mở)',
                result.extractedUrls,
                Icons.link_off_outlined,
              ),
            if (result.ocrExtractedText != null)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Văn bản đọc từ ảnh'),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SelectableText(result.ocrExtractedText!),
                  ),
                ],
              ),
            if (result.multiAgentDebate?.isComplete == true)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                initiallyExpanded: true,
                title: const Text('Phân tích của 3 AI'),
                children: [
                  _section(
                    'AI 1 · Phân tích rủi ro',
                    result.multiAgentDebate!.threatHunterAnalysis,
                  ),
                  _section(
                    'AI 2 · Phân tích an toàn',
                    result.multiAgentDebate!.auditorDefense,
                  ),
                  _section(
                    'AI 3 · Kết luận',
                    result.multiAgentDebate!.arbiterVerdict,
                  ),
                ],
              ),
            if (result.messages.isNotEmpty)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Nội dung hội thoại'),
                children: [
                  for (final message in result.messages)
                    _field(_sender(message.sender), message.text),
                ],
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: safeScanSummary(result, level.label)),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã sao chép tóm tắt kết quả.'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Sao chép tóm tắt'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: () async {
                try {
                  await SharePlus.instance.share(
                    ShareParams(text: safeScanSummary(result, level.label)),
                  );
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Không mở được bảng chia sẻ.'),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.share_outlined),
              label: const Text('Chia sẻ tóm tắt'),
            ),
            const SizedBox(height: 8),
            Text(
              'Kết quả AI chỉ mang tính hỗ trợ. Hãy xác minh thông tin qua kênh chính thức.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        SelectableText(value),
      ],
    ),
  );

  Widget _section(String title, String text) => text.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              SelectableText(text),
            ],
          ),
        );

  Widget _list(String title, List<String> items, IconData icon) {
    final isAdvice = title == 'Nên làm gì';
    final color = isAdvice ? const Color(0xFF047857) : const Color(0xFFB45309);
    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isAdvice ? const Color(0xFFEAF7F1) : const Color(0xFFFFF6E8),
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 7),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 8),
                  Expanded(child: SelectableText(item)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

({String label, Color color}) _level(ScanResult result) {
  if (!result.isChatScreenshot) {
    return (
      label: 'Cần ảnh hoặc văn bản rõ hơn',
      color: const Color(0xFF92400E),
    );
  }
  final score = result.confidenceScore;
  if (score == null) {
    return (
      label: result.isScam ? 'Có dấu hiệu rủi ro' : 'Chưa xác định mức độ',
      color: const Color(0xFF92400E),
    );
  }
  if (!result.isScam && score < 40) {
    return (
      label: 'Chưa thấy dấu hiệu lừa đảo',
      color: const Color(0xFF047857),
    );
  }
  if (score >= 85) {
    return (label: 'Nguy cơ rất cao', color: const Color(0xFFB42318));
  }
  if (score >= 70) {
    return (label: 'Nguy cơ cao', color: const Color(0xFFB42318));
  }
  if (score >= 40) {
    return (label: 'Cần cảnh giác', color: const Color(0xFF92400E));
  }
  return (
    label: result.isScam
        ? 'Có dấu hiệu đáng ngờ'
        : 'Chưa thấy dấu hiệu lừa đảo',
    color: result.isScam ? const Color(0xFF92400E) : const Color(0xFF047857),
  );
}

String _vectorLabel(String value) => switch (value) {
  'phishing_link' => 'Liên kết giả mạo',
  'otp_theft' => 'Yêu cầu OTP hoặc mật khẩu',
  'money_transfer' => 'Yêu cầu chuyển tiền',
  'apk_malware' => 'Ứng dụng/APK đáng ngờ',
  'unauthorized_contact' => 'Liên hệ không chính thức',
  _ => value,
};

String _sender(String value) => switch (value) {
  'scammer' => 'Người gửi',
  'user' => 'Bạn',
  _ => 'Không rõ',
};
