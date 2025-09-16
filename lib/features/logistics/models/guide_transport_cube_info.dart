import 'package:flutter/foundation.dart';

/// Información de una guía dentro de un cubo de transporte
@immutable
class GuideTransportCubeInfo {
  final String packageCode;
  final String state; // Entered | Extracted
  final String? stateLabel;

  const GuideTransportCubeInfo({
    required this.packageCode,
    required this.state,
    this.stateLabel,
  });

  factory GuideTransportCubeInfo.fromJson(Map<String, dynamic> json) {
    return GuideTransportCubeInfo(
      packageCode: json['packageCode'] as String,
      state: json['state'] as String,
      stateLabel: json['stateLabel'] as String?,
    );
  }
}
