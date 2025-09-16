
/// Constantes de estados del backend para tracking de guías.
///
/// Estos estados vienen directamente del backend y representan el estado
/// actual de una guía en el sistema de tracking.

class BackendTrackingState {
  /// Estado cuando la guía está lista para despacho
  static const String READY_FOR_SHIPMENT = 'ReadyForShipment';

  /// Estado cuando la guía está despachada desde aduana
  static const String DISPATCHED_FROM_CUSTOMS = 'DispatchedFromCustoms';

  /// Estado cuando la guía está en tránsito a bodega
  static const String TRANSIT_TO_WAREHOUSE = 'TransitToWarehouse';

  /// Estado cuando la guía está recibida en bodega local
  static const String RECEIVED_IN_LOCAL_WAREHOUSE = 'ReceivedInLocalWarehouse';

  /// Estado cuando la guía está lista para entrega
  static const String READY_FOR_DELIVERY = 'ReadyForDelivery';

  /// Estado cuando la guía ha sido entregada al destino final
  static const String DELIVERED_TO_FINAL_DESTINATION = 'DeliveredToFinalDestination';

  /// Lista de todos los estados posibles
  static const List<String> values = [
    READY_FOR_SHIPMENT,
    DISPATCHED_FROM_CUSTOMS,
    TRANSIT_TO_WAREHOUSE,
    RECEIVED_IN_LOCAL_WAREHOUSE,
    READY_FOR_DELIVERY,
    DELIVERED_TO_FINAL_DESTINATION,
  ];

  /// Verifica si un estado es válido
  static bool isValidState(String state) {
    return values.contains(state);
  }

  /// Obtiene la etiqueta amigable para mostrar al usuario
  static String getLabel(String state) {
    switch (state) {
      case READY_FOR_SHIPMENT:
        return 'Listo para Despacho';
      case DISPATCHED_FROM_CUSTOMS:
        return 'Despachado de Aduana';
      case TRANSIT_TO_WAREHOUSE:
        return 'Tránsito a Bodega';
      case RECEIVED_IN_LOCAL_WAREHOUSE:
        return 'Recibido en Bodega';
      case READY_FOR_DELIVERY:
        return 'Listo para Entrega';
      case DELIVERED_TO_FINAL_DESTINATION:
        return 'Entregado a Destino Final';
      default:
        return isValidState(state) ? state : 'Desconocido';
    }
  }

  /// Color sugerido para UI por estado
  static int getColor(String state) {
    switch (state) {
      case READY_FOR_SHIPMENT:
        return 0xFF1976D2; // Azul
      case DISPATCHED_FROM_CUSTOMS:
        return 0xFFF57C00; // Naranja
      case TRANSIT_TO_WAREHOUSE:
        return 0xFFFF9800; // Naranja claro
      case RECEIVED_IN_LOCAL_WAREHOUSE:
        return 0xFF7B1FA2; // Morado
      case READY_FOR_DELIVERY:
        return 0xFF00897B; // Verde azulado
      case DELIVERED_TO_FINAL_DESTINATION:
        return 0xFF2E7D32; // Verde
      default:
        return 0xFF9E9E9E; // Gris
    }
  }

  /// Ícono sugerido para UI por estado
  static String getIconName(String state) {
    switch (state) {
      case READY_FOR_SHIPMENT:
        return 'inventory_2';
      case DISPATCHED_FROM_CUSTOMS:
        return 'local_shipping';
      case TRANSIT_TO_WAREHOUSE:
        return 'directions_run';
      case RECEIVED_IN_LOCAL_WAREHOUSE:
        return 'warehouse';
      case READY_FOR_DELIVERY:
        return 'delivery_dining';
      case DELIVERED_TO_FINAL_DESTINATION:
        return 'where_to_vote';
      default:
        return 'info_outline';
    }
  }

  /// Obtiene el siguiente estado posible según el estado actual
  static String? getNextState(String currentState) {
    switch (currentState) {
      case READY_FOR_SHIPMENT:
        return DISPATCHED_FROM_CUSTOMS;
      case DISPATCHED_FROM_CUSTOMS:
        return TRANSIT_TO_WAREHOUSE;
      case TRANSIT_TO_WAREHOUSE:
        return RECEIVED_IN_LOCAL_WAREHOUSE;
      case RECEIVED_IN_LOCAL_WAREHOUSE:
        return READY_FOR_DELIVERY;
      case READY_FOR_DELIVERY:
        return DELIVERED_TO_FINAL_DESTINATION;
      default:
        return null;
    }
  }

}
