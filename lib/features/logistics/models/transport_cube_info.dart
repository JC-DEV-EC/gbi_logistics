import 'package:flutter/foundation.dart';
import 'cube_type.dart';

/// Información de un cubo de transporte (para listado)
@immutable
class TransportCubeInfo {
  final int id;
  final DateTime registerDateTime;
  final String state; // Created | Sent | Downloading | Downloaded
  final int guides; // cantidad de guías
  final String? stateLabel;
  final CubeType type;
  final String? typeLabel;
  final String? operatorName;

  const TransportCubeInfo({
    required this.id,
    required this.registerDateTime,
    required this.state,
    required this.guides,
    required this.type,
    this.stateLabel,
    this.typeLabel,
    this.operatorName,
  });

  factory TransportCubeInfo.fromJson(Map<String, dynamic> json) {
    return TransportCubeInfo(
      id: json['id'] as int,
      registerDateTime: DateTime.parse(json['registerDateTime'] as String),
      state: json['state'] as String,
      guides: json['guides'] as int,
      stateLabel: json['stateLabel'] as String?,
      type: CubeType.fromDynamic(json['type']) ?? CubeType.transitToWarehouse,
      typeLabel: json['typeLabel'] as String?,
      operatorName: json['operatorName'] as String?,
    );
  }
}

