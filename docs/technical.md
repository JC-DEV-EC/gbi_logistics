# Technical Documentation - GBI Logistics

## Arquitectura

### Estructura del Proyecto

La aplicación sigue una arquitectura modular basada en características (feature-based) con una clara separación de responsabilidades:

```
lib/
├── core/                 # Funcionalidad base y compartida
│   ├── config/          # Configuración global
│   ├── observers/       # Observadores del ciclo de vida
│   ├── services/        # Servicios base (HTTP, storage)
│   └── widgets/         # Widgets compartidos
└── features/            # Módulos de características
    └── logistics/       # Módulo principal de logística
        ├── models/      # Modelos de datos
        ├── providers/   # Gestores de estado
        ├── screens/     # Pantallas de la UI
        ├── services/    # Servicios de negocio
        └── widgets/     # Widgets específicos
```

### Patrones de Diseño

1. **Provider Pattern**
   - Implementado para gestión de estado global
   - Providers principales:
     - `AuthProvider`: Gestión de autenticación
     - `GuideProvider`: Gestión de guías
     - `TransportCubeProvider`: Gestión de cubos de transporte

2. **Repository Pattern**
   - Implementado en los servicios
   - Abstracción de la capa de datos
   - Servicios principales:
     - `AuthService`
     - `GuideService`
     - `TransportCubeService`

3. **Observer Pattern**
   - Usado para ciclo de vida de la aplicación
   - Implementado en `AuthLifecycleObserver`

4. **Factory Pattern**
   - Utilizado en la creación de modelos
   - Conversión entre DTOs y modelos de dominio

## Implementación

### Gestión de Estado

La aplicación utiliza Provider como solución de gestión de estado:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider(authService),
    ),
    ChangeNotifierProvider<GuideProvider>(
      create: (_) => GuideProvider(guideService),
    ),
    ChangeNotifierProvider<TransportCubeProvider>(
      create: (_) => TransportCubeProvider(transportCubeService)..loadCubes(),
    ),
  ],
  child: MaterialApp(...),
)
```

### Autenticación

1. **Flujo de Token**
   - Refresh token automático
   - Verificación periódica del estado de autenticación
   - Manejo de expiración de sesión

2. **Ciclo de Vida**
   - Verificación de estado al resumir la aplicación
   - Gestión de estado de autenticación global

### Navegación

Sistema de rutas basado en estados:

```dart
onGenerateRoute: (settings) {
  switch (settings.name) {
    case '/customs-dispatch':
      return MaterialPageRoute(
        builder: (_) => const CustomsDispatchScreen(),
      );
    // ... otras rutas
  }
}
```

### Manejo de Errores

1. **Error Handling Global**
   - Captura de errores no manejados
   - UI personalizada para errores
   - Logging de errores

2. **Error UI**
   - Widgets de error personalizados
   - Feedback visual para el usuario
   - Recuperación de estados de error

## Componentes Core

### HttpService

Servicio base para comunicación HTTP:
- Manejo de tokens
- Interceptores de respuesta
- Refresh token automático
- Manejo de errores HTTP

### StorageService

Gestión de almacenamiento seguro:
- Almacenamiento de tokens
- Datos de sesión
- Preferencias de usuario

### Lifecycle Management

Gestión del ciclo de vida de la aplicación:
- Observer global de autenticación
- Manejo de estados de la aplicación
- Refresh periódico de tokens

## Consideraciones Técnicas

### Seguridad

1. **Almacenamiento Seguro**
   - Uso de `flutter_secure_storage`
   - Encriptación de datos sensibles
   - Manejo seguro de tokens

2. **Autenticación**
   - Token refresh automático
   - Validación de sesión
   - Manejo de expiración

### Performance

1. **Carga de Datos**
   - Carga inicial optimizada
   - Caching de datos
   - Actualización selectiva

2. **UI/UX**
   - Animaciones optimizadas
   - Carga progresiva
   - Feedback inmediato

### Testing

1. **Unit Tests**
   - Pruebas de servicios
   - Pruebas de providers
   - Mocking de dependencias

2. **Widget Tests**
   - Pruebas de componentes UI
   - Pruebas de navegación
   - Pruebas de integración

## Mejores Prácticas

1. **Code Style**
   - Nombres en PascalCase para clases
   - Nombres en camelCase para métodos y variables
   - Constantes en SCREAMING_SNAKE_CASE

2. **Error Handling**
   - Manejo centralizado de errores
   - Logging estructurado
   - Recuperación de errores

3. **State Management**
   - Actualización atómica de estado
   - Inmutabilidad de modelos
   - Separación de lógica de negocio

4. **Documentation**
   - Documentación de APIs públicas
   - Ejemplos de uso
   - Documentación de arquitectura