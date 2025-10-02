import 'package:flutter/material.dart';

/// Estados posibles de un cubo de transporte
/// 
/// Estos estados representan el ciclo de vida de un cubo en el sistema,
/// desde su creación hasta el despacho final de sus guías.
/// Estados válidos para cubos de transporte según la API
class TransportCubeState {
  /// Estado cuando el cubo es creado en despacho de aduana
  static const String created = 'Created';

  /// Estado cuando el cubo es enviado a tránsito en bodega
  static const String sent = 'Sent';

  /// Estado cuando el cubo está en recepción en bodega
  static const String downloading = 'Downloading';

  /// Estado cuando el cubo está listo para despacho a cliente
  static const String downloaded = 'Downloaded';

  /// Lista de todos los estados posibles
  static const List<String> values = [
    created,
    sent,
    downloading,
    downloaded,
  ];

  /// Obtiene la etiqueta amigable para mostrar al usuario
  static String getLabel(String state) {
    switch (state) {
      case created:
        return 'Despacho en Aduana';
      case sent:
        return 'Tránsito en Bodega';
      case downloading:
        return 'Recepción en Bodega';
      case downloaded:
        return 'Despacho a Cliente';
      default:
        return 'Desconocido';
    }
  }

  /// Color sugerido para UI por estado
  static int getColor(String state) {
    switch (state) {
      case created:
        return 0xFF1976D2; // Azul
      case sent:
        return 0xFFF57C00; // Naranja
      case downloading:
        return 0xFF7B1FA2; // Morado
      case downloaded:
        return 0xFF2E7D32; // Verde
      default:
        return 0xFF9E9E9E; // Gris
    }
  }

  /// Ícono sugerido para UI por estado
  static IconData getIcon(String state) {
    switch (state) {
      case created:
        return Icons.local_shipping;
      case sent:
        return Icons.directions_run;
      case downloading:
        return Icons.downloading;
      case downloaded:
        return Icons.check_circle;
      default:
        return Icons.info_outline;
    }
  }
}
