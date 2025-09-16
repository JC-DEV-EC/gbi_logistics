import 'package:flutter/foundation.dart';
import 'backend_tracking_state.dart';

/// Modelo de guía de envío
@immutable
class Guide {
  /// Código único de la guía
  final String packageCode;

  /// Estado actual de tracking
  final String state;

  /// Fecha y hora de la última actualización
  final DateTime lastUpdateDateTime;

  /// Subcorreo asignado (opcional)
  final int? subcourierId;

  const Guide({
    required this.packageCode,
    required this.state,
    required this.lastUpdateDateTime,
    this.subcourierId,
  });

  /// Crea una guía desde un mapa de datos
  factory Guide.fromJson(Map<String, dynamic> json) {
    return Guide(
      packageCode: json['packageCode'] as String,
      state: json['state'] as String,
      lastUpdateDateTime: DateTime.parse(json['lastUpdateDateTime'] as String),
      subcourierId: json['subcourierId'] as int?,
    );
  }

  /// Convierte la guía a un mapa de datos
  Map<String, dynamic> toJson() {
    return {
      'packageCode': packageCode,
      'state': state,
      'lastUpdateDateTime': lastUpdateDateTime.toIso8601String(),
      'subcourierId': subcourierId,
    };
  }

  /// Obtiene la etiqueta del estado para mostrar al usuario
  String get stateLabel => BackendTrackingState.getLabel(state);
}
