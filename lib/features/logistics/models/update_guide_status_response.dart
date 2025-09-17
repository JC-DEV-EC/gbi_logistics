class UpdateGuideStatusResponse {
  final String? guideCode;
  final int statusId;
  final String? subStatusId;
  final String? observation;

  UpdateGuideStatusResponse({
    this.guideCode,
    required this.statusId,
    this.subStatusId,
    this.observation,
  });

  factory UpdateGuideStatusResponse.fromJson(Map<String, dynamic> json) {
    return UpdateGuideStatusResponse(
      guideCode: json['guideCode'] as String?,
      statusId: json['statusId'] as int,
      subStatusId: json['subStatusId'] as String?,
      observation: json['observation'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'guideCode': guideCode,
    'statusId': statusId,
    'subStatusId': subStatusId,
    'observation': observation,
  };
}