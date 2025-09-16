# Flujo de Estados - GBI Logistics

## Descripción General

El sistema implementa un flujo de estados para los cubos de transporte que determina su ubicación y estado actual en el proceso logístico. Cada estado corresponde a una pantalla específica donde se muestran y gestionan los cubos en ese estado.

## Estados y Pantallas

### 1. Despacho en Aduana (`CustomsDispatchScreen`)
- **Estado del Cubo**: `TransportCubeState.created`
- **UI muestra**: "Despachado de Aduana"
- **Ubicación**: `/customs-dispatch`
- **Acciones disponibles**:
  - Ver detalles del cubo
  - Seleccionar cubos
  - Enviar cubos a bodega (cambio a estado `sent`)

### 2. Tránsito a Bodega (`WarehouseTransitScreen`)
- **Estado del Cubo**: `TransportCubeState.sent`
- **UI muestra**: "Tránsito a Bodega"
- **Ubicación**: `/warehouse-transit`
- **Acciones disponibles**:
  - Ver detalles del cubo
  - Marcar como recibido (cambio a estado `downloading`)

### 3. Recepción en Bodega (`WarehouseReceptionScreen`)
- **Estado del Cubo**: `TransportCubeState.downloading`
- **Estado de Guías**: `TrackingStateType.receivedInLocalWarehouse`
- **UI muestra**: "Recibido en Bodega Local"
- **Ubicación**: `/warehouse-reception`
- **Acciones disponibles**:
  - Escanear guías
  - Actualizar estado de guías
  - Completar recepción (cambio a estado `downloaded`)

### 4. Listo para Entrega (`DispatchRequestScreen`)
- **Estado del Cubo**: `TransportCubeState.downloaded`
- **UI muestra**: "Listo para Entrega"
- **Ubicación**: `/dispatch-request`
- **Acciones disponibles**:
  - Crear nuevos cubos
  - Agregar guías
  - Guardar y enviar cubos

## Navegación Automática

El sistema implementa navegación automática basada en el estado del cubo:

```dart
switch (newState) {
  case TransportCubeState.created:
    Navigator.pushReplacementNamed(context, '/customs-dispatch');
    break;
  case TransportCubeState.sent:
    Navigator.pushReplacementNamed(context, '/warehouse-transit');
    break;
  case TransportCubeState.downloading:
    Navigator.pushReplacementNamed(context, '/warehouse-reception');
    break;
  case TransportCubeState.downloaded:
    Navigator.pushReplacementNamed(context, '/dispatch-request');
    break;
}
```

## Filtrado de Cubos por Estado

Cada pantalla filtra y muestra solo los cubos en el estado correspondiente:

1. `CustomsDispatchScreen`: Muestra cubos en estado `created`
2. `WarehouseTransitScreen`: Muestra cubos en estado `sent`
3. `WarehouseReceptionScreen`: Muestra cubos en estado `downloading`
4. Lista para entrega: Muestra cubos en estado `downloaded`

## Cambios de Estado

### Transiciones Permitidas:

1. `created` → `sent`
   - Trigger: Botón "Enviar" en CustomsDispatchScreen
   - Acción: `changeSelectedCubesState(TransportCubeState.sent)`

2. `sent` → `downloading`
   - Trigger: Botón "Recibir" en WarehouseTransitScreen
   - Acción: `changeSelectedCubesState(TransportCubeState.downloading)`

3. `downloading` → `downloaded`
   - Trigger: Completar recepción en WarehouseReceptionScreen
   - Acción: `changeSelectedCubesState(TransportCubeState.downloaded)`

### Actualización de Guías:

Las guías dentro de los cubos se actualizan cuando:
- El cubo cambia a estado `downloading`
- Se completa la recepción del cubo
- Se marca el cubo como listo para entrega

## Implementación del Filtrado

```dart
// Ejemplo de filtrado en WarehouseTransitScreen
final cubesInTransit = provider.cubes.where(
  (cube) => cube.state == TransportCubeState.sent
).toList();
```

## Consideraciones de UX

1. **Visibilidad de Estado**:
   - Cada pantalla muestra claramente el estado actual
   - Los cambios de estado tienen confirmación visual
   - Se muestran indicadores de progreso durante las transiciones

2. **Navegación**:
   - La navegación es automática al cambiar estados
   - Se mantiene consistencia en la UI entre estados
   - El usuario puede navegar manualmente entre estados

3. **Validaciones**:
   - Se validan las transiciones de estado
   - Se previenen cambios de estado inválidos
   - Se manejan errores y casos edge
