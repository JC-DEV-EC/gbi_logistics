import 'package:flutter/foundation.dart';

/// Modelo para el historial de cambios de estado de un cubo
@immutable
class TransportCubeHistory {
  final String state;
  final DateTime date;
  final String description;

  const TransportCubeHistory({
    required this.state,
    required this.date,
    required this.description,
  });
}
