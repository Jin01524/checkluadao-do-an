import 'package:flutter/material.dart';

import '../../core/models/scam_template.dart';
import 'template_repository.dart';

class TemplateDetailPage extends StatefulWidget {
  const TemplateDetailPage({
    super.key,
    required this.repository,
    required this.id,
  });
  final TemplateRepository repository;
  final String id;

  @override
  State<TemplateDetailPage> createState() => _TemplateDetailPageState();
}

class _TemplateDetailPageState extends State<TemplateDetailPage> {
  ScamTemplate? _item;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final item = await widget.repository.detail(widget.id);
      if (mounted) setState(() => _item = item);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết mẫu tin nhắn')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    TextButton(onPressed: _load, child: const Text('Thử lại')),
                  ],
                ),
              ),
            )
          : item == null
          ? const Center(child: Text('Không tìm thấy mẫu này.'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'PHÂN TÍCH TÌNH HUỐNG',
                  style: TextStyle(
                    color: Color(0xFF0037B0),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Card(
                  color: item.isApproved
                      ? const Color(0xFFE6F5EC)
                      : const Color(0xFFFFF2D9),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.isApproved
                              ? 'Đã được kiểm duyệt'
                              : 'Chưa được kiểm duyệt',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        if (!item.isApproved) ...[
                          const SizedBox(height: 4),
                          const Text(
                            'Thông tin này chưa được xác minh thủ công. Không xem kết luận AI là bằng chứng chắc chắn.',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (item.isSafe)
                  const Card(
                    color: Color(0xFFE6F5EC),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'AI đánh giá tin nhắn này là an toàn. Hãy xác minh thêm nếu có yêu cầu chuyển tiền hoặc cung cấp thông tin.',
                      ),
                    ),
                  )
                else if (item.confidenceScore != null)
                  Card(
                    color: const Color(0xFFFFE8E8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ĐÁNH GIÁ RỦI RO',
                            style: TextStyle(
                              color: Color(0xFFBA1A1A),
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${item.confidenceScore}/100',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: const Color(0xFFBA1A1A),
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: item.confidenceScore! / 100,
                            minHeight: 7,
                            color: const Color(0xFFBA1A1A),
                            backgroundColor: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                _field('Hình thức', item.scamType),
                _field('Nền tảng', item.platform),
                if (item.attackTarget != null)
                  _field('Mục tiêu', item.attackTarget!),
                if (item.multiAgentDebate?.isComplete == true) ...[
                  _field(
                    'AI 1 · Phân tích rủi ro',
                    item.multiAgentDebate!.threatHunterAnalysis,
                  ),
                  _field(
                    'AI 2 · Phân tích an toàn',
                    item.multiAgentDebate!.auditorDefense,
                  ),
                  _field(
                    'AI 3 · Kết luận',
                    item.multiAgentDebate!.arbiterVerdict,
                  ),
                ] else if (item.analysis.isNotEmpty)
                  _field('Phân tích của AI', item.analysis),
                if (item.warningPoints.isNotEmpty)
                  _field('Dấu hiệu', item.warningPoints.join('\n• ')),
                if (item.messages.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Nội dung hội thoại',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  for (final message in item.messages)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.sender == 'user' ? 'Bạn' : 'Người gửi',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SelectableText(message.text),
                          ],
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Mẫu này chỉ để tham khảo. Không truy cập liên kết hoặc liên hệ số điện thoại xuất hiện trong nội dung nghi vấn.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF52627A)),
                ),
              ],
            ),
    );
  }

  Widget _field(String label, String value) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          SelectableText(value),
        ],
      ),
    ),
  );
}
