
/// Constantes de estados del backend para tracking de guías.
///
/// Estos estados vienen directamente del backend y representan el estado
/// actual de una guía en el sistema de tracking.
class BackendTrackingState {
  /// Estado cuando la guía está lista para despacho
  static const String readyForShipment = 'ReadyForShipment';

  /// Estado cuando la guía está despachada desde aduana
  static const String dispatchedFromCustoms = 'DispatchedFromCustoms';

  /// Estado cuando la guía está en tránsito a bodega
  static const String transitToWarehouse = 'TransitToWarehouse';

  /// Estado cuando la guía está recibida en bodega local
  static const String receivedInLocalWarehouse = 'ReceivedInLocalWarehouse';

  /// Estado cuando la guía está lista para entrega
  static const String readyForDelivery = 'ReadyForDelivery';

  /// Estado cuando la guía ha sido entregada al destino final
  static const String deliveredToFinalDestination = 'DeliveredToFinalDestination';

  /// Lista de todos los estados posibles
  static const List<String> values = [
    readyForShipment,
    dispatchedFromCustoms,
    transitToWarehouse,
    receivedInLocalWarehouse,
    readyForDelivery,
    deliveredToFinalDestination,
  ];

  /// Verifica si un estado es válido
  static bool isValidState(String state) {
    return values.contains(state);
  }

  /// Obtiene la etiqueta amigable para mostrar al usuario
  static String getLabel(String state) {
    switch (state) {
      case readyForShipment:
        return 'Listo para Despacho';
      case dispatchedFromCustoms:
        return 'Despachado de Aduana';
      case transitToWarehouse:
        return 'Tránsito a Bodega';
      case receivedInLocalWarehouse:
        return 'Recibido en Bodega';
      case readyForDelivery:
        return 'Listo para Entrega';
      case deliveredToFinalDestination:
        return 'Entregado a Destino Final';
      default:
        return isValidState(state) ? state : 'Desconocido';
    }
  }

  /// Color sugerido para UI por estado
  static int getColor(String state) {
    switch (state) {
      case readyForShipment:
        return 0xFF1976D2; // Azul
      case dispatchedFromCustoms:
        return 0xFFF57C00; // Naranja
      case transitToWarehouse:
        return 0xFFFF9800; // Naranja claro
      case receivedInLocalWarehouse:
        return 0xFF7B1FA2; // Morado
      case readyForDelivery:
        return 0xFF00897B; // Verde azulado
      case deliveredToFinalDestination:
        return 0xFF2E7D32; // Verde
      default:
        return 0xFF9E9E9E; // Gris
    }
  }

  /// Ícono sugerido para UI por estado
  static String getIconName(String state) {
    switch (state) {
      case readyForShipment:
        return 'inventory_2';
      case dispatchedFromCustoms:
        return 'local_shipping';
      case transitToWarehouse:
        return 'directions_run';
      case receivedInLocalWarehouse:
        return 'warehouse';
      case readyForDelivery:
        return 'delivery_dining';
      case deliveredToFinalDestination:
        return 'where_to_vote';
      default:
        return 'info_outline';
    }
  }

  /// Obtiene el siguiente estado posible según el estado actual
  static String? getNextState(String currentState) {
    switch (currentState) {
      case readyForShipment:
        return dispatchedFromCustoms;
      case dispatchedFromCustoms:
        return transitToWarehouse;
      case transitToWarehouse:
        return receivedInLocalWarehouse;
      case receivedInLocalWarehouse:
        return readyForDelivery;
      case readyForDelivery:
        return deliveredToFinalDestination;
      default:
        return null;
    }
  }

}
