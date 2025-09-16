import 'package:flutter/material.dart';

/// Estados posibles de un cubo de transporte
/// 
/// Estos estados representan el ciclo de vida de un cubo en el sistema,
/// desde su creación hasta el despacho final de sus guías.
/// Estados válidos para cubos de transporte según la API
class TransportCubeState {
  /// Estado cuando el cubo es creado en despacho de aduana
  static const String CREATED = 'Created';

  /// Estado cuando el cubo es enviado a tránsito en bodega
  static const String SENT = 'Sent';

  /// Estado cuando el cubo está en recepción en bodega
  static const String DOWNLOADING = 'Downloading';

  /// Estado cuando el cubo está listo para despacho a cliente
  static const String DOWNLOADED = 'Downloaded';

  /// Lista de todos los estados posibles
  static const List<String> values = [
    CREATED,
    SENT,
    DOWNLOADING,
    DOWNLOADED,
  ];

  /// Obtiene la etiqueta amigable para mostrar al usuario
  static String getLabel(String state) {
    switch (state) {
      case CREATED:
        return 'Despacho en Aduana';
      case SENT:
        return 'Tránsito en Bodega';
      case DOWNLOADING:
        return 'Recepción en Bodega';
      case DOWNLOADED:
        return 'Despacho a Cliente';
      default:
        return 'Desconocido';
    }
  }

  /// Color sugerido para UI por estado
  static int getColor(String state) {
    switch (state) {
      case CREATED:
        return 0xFF1976D2; // Azul
      case SENT:
        return 0xFFF57C00; // Naranja
      case DOWNLOADING:
        return 0xFF7B1FA2; // Morado
      case DOWNLOADED:
        return 0xFF2E7D32; // Verde
      default:
        return 0xFF9E9E9E; // Gris
    }
  }

  /// Ícono sugerido para UI por estado
  static IconData getIcon(String state) {
    switch (state) {
      case CREATED:
        return Icons.local_shipping;
      case SENT:
        return Icons.directions_run;
      case DOWNLOADING:
        return Icons.downloading;
      case DOWNLOADED:
        return Icons.check_circle;
      default:
        return Icons.info_outline;
    }
  }
}
