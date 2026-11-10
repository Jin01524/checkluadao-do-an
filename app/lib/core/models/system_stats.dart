class SystemStats {
  const SystemStats({
    required this.totalScans,
    required this.warnedScans,
    required this.maxConfidence,
  });
  final int totalScans;
  final int warnedScans;
  final int maxConfidence;

  double get warningPercent =>
      totalScans == 0 ? 0 : warnedScans * 100 / totalScans;

  factory SystemStats.fromJson(Map<String, dynamic> json) {
    final total = json['totalScans'];
    final warned = json['warnedScans'];
    if (total is! int ||
        warned is! int ||
        total < 0 ||
        warned < 0 ||
        warned > total) {
      throw const FormatException('Số liệu lượt quét không hợp lệ.');
    }
    return SystemStats(
      totalScans: total,
      warnedScans: warned,
      maxConfidence: (json['maxConfidence'] as num?)?.toInt() ?? 0,
    );
  }
}
