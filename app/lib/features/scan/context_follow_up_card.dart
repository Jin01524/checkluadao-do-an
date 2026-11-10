import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/scan_result.dart';

class ContextFollowUpCard extends StatefulWidget {
  const ContextFollowUpCard({
    super.key,
    required this.result,
    required this.busy,
    required this.onNewScan,
  });

  final ScanResult result;
  final bool busy;
  final VoidCallback onNewScan;

  @override
  State<ContextFollowUpCard> createState() => _ContextFollowUpCardState();
}

class _ContextFollowUpCardState extends State<ContextFollowUpCard> {
  final _suggestion = TextEditingController();
  bool _skipSuggestion = false;

  @override
  void initState() {
    super.initState();
    _suggestion.text = widget.result.suggestedReply?.text ?? '';
  }

  @override
  void didUpdateWidget(covariant ContextFollowUpCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.result, widget.result)) {
      _suggestion.text = widget.result.suggestedReply?.text ?? '';
      _skipSuggestion = false;
    }
  }

  @override
  void dispose() {
    _suggestion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reply = widget.result.suggestedReply;
    final invalid = widget.result.assessmentStatus == 'invalid_input';
    return Card(
      key: const Key('context_follow_up'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              invalid ? 'CHƯA ĐỌC ĐƯỢC NỘI DUNG' : 'CHƯA ĐỦ NGỮ CẢNH',
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFF92400E),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.result.assessmentReason ??
                  'Chưa thể kết luận từ đoạn tin này.',
            ),
            const SizedBox(height: 8),
            Text(
              invalid
                  ? 'Hãy chụp lại ảnh rõ hơn hoặc dán nội dung để quét lại.'
                  : 'Chưa thể xác nhận tin an toàn. Lượt này không được lưu.',
              style: TextStyle(color: Color(0xFF92400E), fontSize: 12),
            ),
            if (!invalid &&
                !_skipSuggestion &&
                reply != null &&
                reply.text.isNotEmpty) ...[
              const SizedBox(height: 18),
              Container(
                key: const Key('suggested_reply_highlight'),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF4FF),
                  border: Border.all(color: const Color(0xFF0037B0), width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          color: Color(0xFF0037B0),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'TIN NHẮN AI GỢI Ý ĐỂ HỎI LẠI',
                            style: TextStyle(
                              color: Color(0xFF0037B0),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const Key('suggested_reply'),
                      controller: _suggestion,
                      maxLength: 160,
                      minLines: 2,
                      maxLines: 4,
                      enabled: !widget.busy,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF0B1C30),
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Nội dung có thể chỉnh sửa trước khi gửi',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Với số/tài khoản lạ, trả lời có thể xác nhận bạn đang hoạt động. Bạn có thể bỏ qua.',
                style: TextStyle(fontSize: 12, color: Color(0xFF52627A)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: widget.busy
                        ? null
                        : () async {
                            await Clipboard.setData(
                              ClipboardData(text: _suggestion.text.trim()),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Đã sao chép câu hỏi. Bạn tự gửi trong cuộc trò chuyện.',
                                  ),
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.copy),
                    label: const Text('Sao chép tin nhắn'),
                  ),
                  TextButton(
                    onPressed: widget.busy
                        ? null
                        : () => setState(() => _skipSuggestion = true),
                    child: const Text('Bỏ qua'),
                  ),
                ],
              ),
            ],
            if (!invalid) ...[
              const SizedBox(height: 18),
              Text(
                'Khi có phản hồi mới, bắt đầu lượt quét mới',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Chụp hoặc dán lại đoạn hội thoại gồm tin ban đầu và phản hồi mới. App sẽ phân tích riêng lượt đó, không giữ phiên cũ.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Lời người gửi tự khai không chứng minh danh tính. Không gửi tiền, OTP hoặc mở liên kết để kiểm tra.',
                style: TextStyle(fontSize: 12, color: Color(0xFF52627A)),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('start_new_scan'),
              onPressed: widget.busy ? null : widget.onNewScan,
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Quét lượt mới'),
            ),
          ],
        ),
      ),
    );
  }
}
