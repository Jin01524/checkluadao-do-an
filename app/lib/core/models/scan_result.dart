class ScanResult {
  const ScanResult({
    required this.isScam,
    required this.analysis,
    this.confidenceScore,
    this.isChatScreenshot = true,
    this.scamType,
    this.title,
    this.attackTarget,
    this.exfiltrationVector = 'none',
    this.warningPoints = const [],
    this.recommendations = const [],
    this.extractedUrls = const [],
    this.messages = const [],
    this.ocrExtractedText,
    this.multiAgentDebate,
    this.savedTemplateId,
    this.templateSaveStatus,
    this.scanSessionId,
    this.assessmentStatus,
    this.assessmentReason,
    this.suggestedReply,
    this.changedBecause,
  });

  final bool isScam;
  final bool isChatScreenshot;
  final int? confidenceScore;
  final String analysis;
  final String? scamType;
  final String? title;
  final String? attackTarget;
  final String exfiltrationVector;
  final List<String> warningPoints;
  final List<String> recommendations;
  final List<String> extractedUrls;
  final List<ScanMessage> messages;
  final String? ocrExtractedText;
  final Debate? multiAgentDebate;
  final String? savedTemplateId;
  final String? templateSaveStatus;
  final String? scanSessionId;
  final String? assessmentStatus;
  final String? assessmentReason;
  final SuggestedReply? suggestedReply;
  final String? changedBecause;

  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
    isScam: json['isScam'] == true,
    isChatScreenshot: json['isChatScreenshot'] != false,
    confidenceScore: json['assessment'] is Map
        ? parseRiskScore((json['assessment'] as Map)['riskScore'])
        : parseRiskScore(json['confidenceScore']),
    analysis: stringValue(json['analysis']) ?? '',
    scamType: stringValue(json['scamType']),
    title: stringValue(json['title']),
    attackTarget: stringValue(json['attackTarget']),
    exfiltrationVector: stringValue(json['exfiltrationVector']) ?? 'none',
    warningPoints: stringList(json['warningPoints']),
    recommendations: stringList(json['recommendations']),
    extractedUrls: stringList(json['extractedUrls']),
    messages: objectList(json['messages']).map(ScanMessage.fromJson).toList(),
    ocrExtractedText: stringValue(json['ocrExtractedText']),
    multiAgentDebate: json['multiAgentDebate'] is Map
        ? Debate.fromJson(Map<String, dynamic>.from(json['multiAgentDebate']))
        : null,
    savedTemplateId: stringValue(json['savedTemplateId']),
    templateSaveStatus: stringValue(json['templateSaveStatus']),
    scanSessionId: stringValue(json['scanSessionId']),
    assessmentStatus: json['assessment'] is Map
        ? stringValue((json['assessment'] as Map)['status']) : null,
    assessmentReason: json['assessment'] is Map
        ? stringValue((json['assessment'] as Map)['reason']) : null,
    suggestedReply: json['suggestedReply'] is Map
        ? SuggestedReply.fromJson(Map<String, dynamic>.from(json['suggestedReply']))
        : null,
    changedBecause: stringValue(json['changedBecause']),
  );
}

class SuggestedReply {
  const SuggestedReply({required this.text, required this.round, this.purpose});
  final String text;
  final int round;
  final String? purpose;

  factory SuggestedReply.fromJson(Map<String, dynamic> json) => SuggestedReply(
    text: stringValue(json['text']) ?? '',
    round: (json['round'] is num ? (json['round'] as num).toInt() : 1),
    purpose: stringValue(json['purpose']),
  );
}

class ScanMessage {
  const ScanMessage({required this.sender, required this.text});
  final String sender;
  final String text;

  factory ScanMessage.fromJson(Map<String, dynamic> json) => ScanMessage(
    sender: stringValue(json['sender']) ?? 'unknown',
    text: stringValue(json['text']) ?? '',
  );
}

class Debate {
  const Debate({
    required this.threatHunterAnalysis,
    required this.auditorDefense,
    required this.arbiterVerdict,
  });
  final String threatHunterAnalysis;
  final String auditorDefense;
  final String arbiterVerdict;

  bool get isComplete =>
      threatHunterAnalysis.trim().isNotEmpty &&
      auditorDefense.trim().isNotEmpty &&
      arbiterVerdict.trim().isNotEmpty;

  factory Debate.fromJson(Map<String, dynamic> json) => Debate(
    threatHunterAnalysis: stringValue(json['threatHunterAnalysis']) ?? '',
    auditorDefense: stringValue(json['auditorDefense']) ?? '',
    arbiterVerdict: stringValue(json['arbiterVerdict']) ?? '',
  );
}

int? parseRiskScore(Object? value) {
  if (value == null || value == '') return null;
  final number = value is num ? value : num.tryParse(value.toString());
  if (number == null || !number.isFinite) return null;
  // Fractional legacy values represent 0–1; the integer 1 is a valid 1/100 risk score.
  final scaled = number > 0 && number < 1 ? number * 100 : number;
  return scaled.round().clamp(0, 100);
}

String? stringValue(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

List<String> stringList(Object? value) {
  if (value is! List) return const [];
  return value.map(stringValue).whereType<String>().toList();
}

List<Map<String, dynamic>> objectList(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}
