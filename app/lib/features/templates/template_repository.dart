import '../../core/api/api_client.dart';
import '../../core/models/scam_template.dart';

class TemplateListPage {
  const TemplateListPage({
    required this.items,
    required this.nextOffset,
    required this.hasMore,
  });
  final List<ScamTemplate> items;
  final int nextOffset;
  final bool hasMore;
}

class TemplateRepository {
  const TemplateRepository(this._api);
  final ApiClient _api;

  Future<TemplateListPage> list({
    String search = '',
    int limit = 20,
    int offset = 0,
  }) async {
    final body = await _api.get(
      '/api/templates',
      query: {
        'limit': '$limit',
        'offset': '$offset',
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final raw = body['data'];
    if (raw is! List) {
      throw const FormatException('Danh sách mẫu không hợp lệ.');
    }
    final items = raw
        .whereType<Map>()
        .map((item) => ScamTemplate.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    final serverHasMore = body['hasMore'];
    return TemplateListPage(
      items: items,
      nextOffset: offset + raw.length,
      hasMore: serverHasMore is bool ? serverHasMore : raw.length == limit,
    );
  }

  Future<ScamTemplate> detail(String id) async {
    final body = await _api.get('/api/templates/${Uri.encodeComponent(id)}');
    final raw = body['data'];
    if (raw is! Map) throw const FormatException('Chi tiết mẫu không hợp lệ.');
    final item = ScamTemplate.fromJson(Map<String, dynamic>.from(raw));
    return item;
  }
}
