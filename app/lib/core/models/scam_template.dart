import 'dart:convert';

import 'scan_result.dart';

class ScamTemplate {
  const ScamTemplate({
    required this.id,
    required this.title,
    required this.platform,
    required this.scamType,
    required this.analysis,
    required this.isApproved,
    this.confidenceScore,
    this.attackTarget,
    this.warningPoints = const [],
    this.messages = const [],
    this.multiAgentDebate,
  });

  final String id;
  final String title;
  final String platform;
  final String scamType;
  final String analysis;
  final bool isApproved;
  final int? confidenceScore;
  final String? attackTarget;
  final List<String> warningPoints;
  final List<ScanMessage> messages;
  final Debate? multiAgentDebate;

  bool get isSafe => scamType == 'Tin nhắn an toàn / Bình thường';

  factory ScamTemplate.fromJson(Map<String, dynamic> json) {
    final warnings = _decode(json['warning_points']);
    final messages = _decode(json['messages_json']);
    final debate = _decode(json['multi_agent_debate']);
    return ScamTemplate(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Mẫu tin nhắn').toString(),
      platform: (json['platform'] ?? 'Không rõ').toString(),
      scamType: (json['scam_type'] ?? 'Nghi vấn lừa đảo').toString(),
      analysis: (json['analysis'] ?? '').toString(),
      isApproved: json['is_approved'] == true,
      confidenceScore: parseRiskScore(json['confidence_score']),
      attackTarget: json['attack_target']?.toString(),
      warningPoints: warnings is List
          ? warnings.map((item) => item.toString()).toList()
          : const [],
      messages: messages is List
          ? messages
                .whereType<Map>()
                .map(
                  (item) =>
                      ScanMessage.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
      multiAgentDebate: debate is Map
          ? Debate.fromJson(Map<String, dynamic>.from(debate))
          : null,
    );
  }
}

Object? _decode(Object? value) {
  if (value is! String) return value;
  try {
    return jsonDecode(value);
  } catch (_) {
    return null;
  }
}
