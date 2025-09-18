# GBI Logistics - Sistema de Despacho y Recepción

Sistema de gestión logística desarrollado en Flutter para el manejo eficiente de despacho y recepción de guías a través de cubos de transporte.

##  Visión General

GBI Logistics es una aplicación móvil diseñada para optimizar el proceso logístico de despacho y recepción de guías, implementando un innovador sistema de cubos de transporte que atraviesan diferentes estados durante el flujo operativo.

## ️ Estructura del Proyecto

```
lib/
├── core/
│   ├── constants/       # Configuración y constantes globales
│   ├── helpers/         # Utilidades y helpers globales
│   ├── models/          # Modelos base
│   ├── services/        # Servicios base (HTTP, manejo de errores)
│   └── widgets/         # Widgets compartidos
└── features/
    └── logistics/
        ├── models/      # Modelos específicos de logística
        ├── presentation/# UI helpers y widgets
        ├── providers/   # Gestión de estado
        ├── screens/     # Pantallas principales
        ├── services/    # Servicios de negocio
        └── widgets/     # Componentes UI específicos
```

##  Estados del Sistema

### Estados de Tracking
- **ReceivedInLocalWarehouse**: Recibido en Bodega Local

### Estados del Cubo de Transporte
1. **Created**: Creado (UI: "Despachado de Aduana")
2. **Sent**: Enviado (UI: "Tránsito a Bodega")
3. **Downloading**: Descargando (UI: "Recibido en Bodega Local")
4. **Downloaded**: Descargado (UI: "Listo para Entrega")

##  Flujo de Proceso

### Proceso de Despacho
1. **Creación de Cubo**
   - Se crea un nuevo cubo con guías seleccionadas
   - Estado inicial: Created

2. **Despacho en Aduana**
   - Permite gestión de guías (agregar/eliminar)
   - UI muestra "Despachado de Aduana"

3. **Envío a Bodega**
   - Cambio a estado Sent
   - UI muestra "Tránsito a Bodega"

### Proceso de Recepción
1. **Inicio de Recepción**
   - Cambio a estado Downloading
   - UI muestra "Recibido en Bodega Local"

2. **Recepción Completada**
   - Actualización de estado de guías
   - Cambio a estado Downloaded
   - UI muestra "Listo para Entrega"

## 🛠 Componentes Principales

### Pantallas
- **CustomsDispatchScreen**: Gestión de despacho aduanero
- **WarehouseReceptionScreen**: Recepción en bodega
- **TransportCubeDetailsScreen**: Detalles y acciones de cubo

### Widgets Clave
- **GuideCounter**: Contador de guías con estado
- **GuideStatusIndicator**: Indicador visual de estado
- **StateFilter**: Filtro de estados

##  Estado Actual

### Implementado ✅
- Estructura base de modelos y enums
- Integración con API
- Flujo básico de estados
- UI base con componentes reusables
- Manejo de errores básico

### En Progreso ⚠️
- Validación de secuencia de estados
- Manejo de errores avanzado
- Optimización de filtros
- Mejoras en UX/UI

##  Próximos Pasos

1. Revisión y corrección de secuencia de estados
2. Implementación de manejo de errores robusto
3. Adición de validaciones
4. Mejora de feedback visual
5. Optimización de rendimiento

## 🔧 Notas Técnicas

### Patrones Implementados
- Repository Pattern (Servicios)
- Provider Pattern (Estado)
- Helper Pattern (Funcionalidad común)
- Factory Pattern (Modelos)

### Consideraciones de Diseño
- Separación clara entre estados backend y UI
- Modelo de datos consistente
- Componentes reutilizables
- Manejo centralizado de errores

##  Comenzando

### Prerrequisitos
- Flutter SDK
- IDE (VS Code o Android Studio recomendado)
- Acceso al repositorio del proyecto

### Instalación
1. Clonar el repositorio
2. Ejecutar `flutter pub get`
3. Configurar variables de entorno necesarias
4. Ejecutar la aplicación con `flutter run`

##  Convenciones de Código

- Nombres de clases en PascalCase
- Nombres de métodos y variables en camelCase
- Constantes en SCREAMING_SNAKE_CASE
- Documentación de clases y métodos públicos

## Documentación

- Visión técnica y arquitectura: [docs/technical.md](docs/technical.md)
- API (endpoints, modelos y estados): [docs/api.md](docs/api.md)
- Guía de desarrollo (setup, flujo y estándares): [docs/development.md](docs/development.md)
- Componentes y UI: [docs/components.md](docs/components.md)
- Flujo de estados: [docs/STATE_FLOW.md](docs/STATE_FLOW.md)

## Ejecución Rápida

1. flutter pub get
2. flutter run

Para más detalles de configuración, consulta [docs/development.md](docs/development.md).
