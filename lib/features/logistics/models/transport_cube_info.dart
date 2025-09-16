import 'package:flutter/foundation.dart';

/// Información de un cubo de transporte (para listado)
@immutable
class TransportCubeInfo {
  final int id;
  final DateTime registerDateTime;
  final String state; // Created | Sent | Downloading | Downloaded
  final int guides; // cantidad de guías
  final String? stateLabel;

  const TransportCubeInfo({
    required this.id,
    required this.registerDateTime,
    required this.state,
    required this.guides,
    this.stateLabel,
  });

  factory TransportCubeInfo.fromJson(Map<String, dynamic> json) {
    return TransportCubeInfo(
      id: json['id'] as int,
      registerDateTime: DateTime.parse(json['registerDateTime'] as String),
      state: json['state'] as String,
      guides: json['guides'] as int,
      stateLabel: json['stateLabel'] as String?,
    );
  }
}

