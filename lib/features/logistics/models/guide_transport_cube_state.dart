import 'package:flutter/material.dart';

/// Estados posibles de una guía dentro de un cubo de transporte
/// 
/// Estos estados representan el estado de una guía específica dentro
/// del cubo, indicando si ha sido ingresada o extraída.
class GuideTransportCubeState {
  /// Estado cuando la guía ha sido ingresada al cubo
  static const String ENTERED = 'Entered';

  /// Estado cuando la guía ha sido extraída del cubo
  static const String EXTRACTED = 'Extracted';

  /// Lista de todos los estados posibles
  static const List<String> values = [
    ENTERED,
    EXTRACTED,
  ];

  /// Obtiene la etiqueta amigable para mostrar al usuario
  static String getLabel(String state) {
    switch (state) {
      case ENTERED:
        return 'Ingresada';
      case EXTRACTED:
        return 'Extraída';
      default:
        return 'Desconocido';
    }
  }

  /// Color sugerido para UI
  static int getColor(String state) {
    switch (state) {
      case ENTERED:
        return 0xFF4CAF50;  // Verde
      case EXTRACTED:
        return 0xFFF44336;  // Rojo
      default:
        return 0xFF9E9E9E;  // Gris
    }
  }

  /// Ícono sugerido para UI
  static IconData getIcon(String state) {
    switch (state) {
      case ENTERED:
        return Icons.check_circle;
      case EXTRACTED:
        return Icons.remove_circle;
      default:
        return Icons.help_outline;
    }
  }
}
