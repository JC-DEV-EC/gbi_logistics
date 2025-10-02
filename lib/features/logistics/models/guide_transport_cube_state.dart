import 'package:flutter/material.dart';

/// Estados posibles de una guía dentro de un cubo de transporte
/// 
/// Estos estados representan el estado de una guía específica dentro
/// del cubo, indicando si ha sido ingresada o extraída.
class GuideTransportCubeState {
  /// Estado cuando la guía ha sido ingresada al cubo
  static const String entered = 'Entered';

  /// Estado cuando la guía ha sido extraída del cubo
  static const String extracted = 'Extracted';

  /// Lista de todos los estados posibles
  static const List<String> values = [
    entered,
    extracted,
  ];

  /// Obtiene la etiqueta amigable para mostrar al usuario
  static String getLabel(String state) {
    switch (state) {
      case entered:
        return 'Ingresada';
      case extracted:
        return 'Extraída';
      default:
        return 'Desconocido';
    }
  }

  /// Color sugerido para UI
  static int getColor(String state) {
    switch (state) {
      case entered:
        return 0xFF4CAF50;  // Verde
      case extracted:
        return 0xFFF44336;  // Rojo
      default:
        return 0xFF9E9E9E;  // Gris
    }
  }

  /// Ícono sugerido para UI
  static IconData getIcon(String state) {
    switch (state) {
      case entered:
        return Icons.check_circle;
      case extracted:
        return Icons.remove_circle;
      default:
        return Icons.help_outline;
    }
  }
}
