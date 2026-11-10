import '../../core/api/api_client.dart';
import '../../core/models/scan_result.dart';
import '../../core/models/system_stats.dart';

class ScanRepository {
  const ScanRepository(this._api);
  final ApiClient _api;

  Future<SystemStats> stats() async =>
      SystemStats.fromJson(await _api.get('/api/stats'));

  Future<ScanResult> scan({
    required String text,
    required List<ScanImage> images,
  }) => _api.scan(text: text, images: images);
}
