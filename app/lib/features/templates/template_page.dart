import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/scam_template.dart';
import 'template_detail_page.dart';
import 'template_repository.dart';

class TemplatePage extends StatefulWidget {
  const TemplatePage({super.key, required this.repository});
  final TemplateRepository repository;

  @override
  State<TemplatePage> createState() => _TemplatePageState();
}

class _TemplatePageState extends State<TemplatePage> {
  static const _pageSize = 20;
  final _search = TextEditingController();
  final _listController = ScrollController();
  final List<ScamTemplate> _items = [];
  Timer? _debounce;
  bool _loading = false;
  bool _hasMore = true;
  int _offset = 0;
  String? _error;
  int _generation = 0;
  String _selectedTopic = '';

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _listController.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading && !reset) return;
    final generation = reset ? ++_generation : _generation;
    if (reset) {
      _items.clear();
      _hasMore = true;
      _offset = 0;
    }
    if (!_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.repository.list(
        search: _search.text,
        limit: _pageSize,
        offset: _offset,
      );
      if (!mounted || generation != _generation) return;
      final existing = _items.map((item) => item.id).toSet();
      setState(() {
        _items.addAll(page.items.where((item) => existing.add(item.id)));
        _offset = page.nextOffset;
        _hasMore = page.hasMore;
      });
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _error = error.toString());
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _listController.hasClients) {
            _listController.animateTo(
              0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView(
        key: const Key('template_page'),
        controller: _listController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        children: [
          if (_error != null)
            Semantics(
              liveRegion: true,
              child: Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(_error!),
                      TextButton(
                        onPressed: () => _load(reset: _items.isEmpty),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE7F0FF), Color(0xFFF5F8FF)],
              ),
              border: Border.all(color: const Color(0xFFCCE0FF)),
              borderRadius: BorderRadius.zero,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'THƯ VIỆN TÌNH HUỐNG',
                  style: TextStyle(
                    color: Color(0xFF0037B0),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Kho mẫu tin nhắn',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0B1C30),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Nhận diện các cách lừa đảo thường gặp. Mỗi mẫu đều ghi rõ trạng thái kiểm duyệt.',
                  style: TextStyle(color: Color(0xFF475569)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            key: const Key('template_search'),
            controller: _search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Xóa tìm kiếm',
                      onPressed: () {
                        _debounce?.cancel();
                        setState(() {
                          _search.clear();
                          _selectedTopic = '';
                        });
                        _load(reset: true);
                      },
                      icon: const Icon(Icons.close),
                    ),
              hintText: 'Tìm hình thức, nội dung...',
            ),
            onChanged: (_) {
              setState(() {
                if (_search.text != _selectedTopic) _selectedTopic = '';
              });
              _debounce?.cancel();
              _debounce = Timer(
                const Duration(milliseconds: 350),
                () => _load(reset: true),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            _items.isEmpty
                ? 'CHỌN CHỦ ĐỀ'
                : 'ĐANG HIỂN THỊ ${_items.length} MẪU CẢNH BÁO',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('Tất cả', ''),
                _filterChip('Ngân hàng', 'ngân hàng'),
                _filterChip('Việc làm', 'việc làm'),
                _filterChip('Công an', 'công an'),
                _filterChip('Đầu tư', 'đầu tư'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_items.isEmpty && _loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
          if (_items.isEmpty && !_loading && _error == null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.search_off,
                      size: 36,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _search.text.isEmpty
                          ? 'Chưa có mẫu cảnh báo để hiển thị.'
                          : 'Không tìm thấy mẫu phù hợp. Thử từ khóa khác.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          for (final item in _items)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TemplateDetailPage(
                      repository: widget.repository,
                      id: item.id,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.report_gmailerrorred_outlined,
                            color: Color(0xFFBA1A1A),
                            size: 26,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF0037B0),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _tag(item.scamType),
                          _reviewTag(item.isApproved),
                          _tag(item.platform),
                          if (item.isSafe)
                            _tag('AI đánh giá an toàn')
                          else if (item.confidenceScore != null)
                            _tag('Rủi ro ${item.confidenceScore}%'),
                        ],
                      ),
                      if (item.analysis.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          item.analysis,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Text(
                        'Xem phân tích  →',
                        style: TextStyle(
                          color: Color(0xFF0037B0),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_hasMore && _items.isNotEmpty && _error == null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OutlinedButton(
                onPressed: _loading ? null : () => _load(),
                child: Text(_loading ? 'Đang tải...' : 'Xem thêm'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFEFF4FF),
      borderRadius: BorderRadius.zero,
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        color: Color(0xFF0037B0),
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _reviewTag(bool approved) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: approved ? const Color(0xFFE6F5EC) : const Color(0xFFFFF1D6),
      borderRadius: BorderRadius.zero,
    ),
    child: Text(
      approved ? 'Đã được kiểm duyệt' : 'Chưa được kiểm duyệt',
      style: TextStyle(
        fontSize: 11,
        color: approved ? const Color(0xFF047857) : const Color(0xFF92400E),
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _filterChip(String label, String query) {
    final active = _selectedTopic == query;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          color: active ? Colors.white : const Color(0xFF334155),
        ),
        selected: active,
        selectedColor: const Color(0xFF1D4ED8),
        backgroundColor: Colors.white,
        showCheckmark: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(
            color: active ? const Color(0xFF1D4ED8) : const Color(0xFFCBD5E1),
          ),
        ),
        onSelected: (_) {
          _debounce?.cancel();
          setState(() {
            _search.text = query;
            _selectedTopic = query;
          });
          _load(reset: true);
        },
      ),
    );
  }
}
