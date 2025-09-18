# Guía de Desarrollo - GBI Logistics

## Requisitos del Sistema

### Software Necesario
1. **Flutter SDK**
   - Versión: >=3.0.0 <4.0.0
   - [Guía de instalación oficial](https://flutter.dev/docs/get-started/install)

2. **IDE Recomendado**
   - Visual Studio Code
     - Extensiones recomendadas:
       - Flutter
       - Dart
       - Flutter Widget Snippets
   - Android Studio
     - Plugins recomendados:
       - Flutter
       - Dart

3. **SDKs adicionales**
   - Android SDK (para desarrollo Android)
   - Xcode (para desarrollo iOS, solo en macOS)
   - Windows SDK (para desarrollo Windows)

4. **Herramientas de Control de Versiones**
   - Git

## Configuración del Entorno

### 1. Clonar el Repositorio
```bash
git clone https://github.com/tu-organizacion/gbi_logistics.git
cd gbi_logistics
```

### 2. Instalar Dependencias
```bash
flutter pub get
```

### 3. Configuración de Variables de Entorno
Crear archivo `.env` en la raíz del proyecto:
```plaintext
API_BASE_URL=https://api.example.com
API_TIMEOUT=30000
ENABLE_DEBUG_LOGS=true
```

### 4. Verificar Configuración
```bash
flutter doctor
```

Asegurarse de que todos los checks estén en verde ✅

## Estructura del Proyecto

```
lib/
├── core/               # Funcionalidad base
│   ├── config/        # Configuración global
│   ├── constants/     # Constantes
│   ├── helpers/       # Utilidades
│   ├── models/        # Modelos base
│   ├── services/      # Servicios base
│   └── widgets/       # Widgets compartidos
├── features/          # Módulos de características
│   └── logistics/     # Módulo principal
│       ├── models/    # Modelos
│       ├── providers/ # Estado
│       ├── screens/   # UI
│       ├── services/  # Servicios
│       └── widgets/   # Componentes
└── main.dart          # Punto de entrada
```

## Flujo de Desarrollo

### 1. Crear Nueva Feature

1. **Estructura de Carpetas**
   ```bash
   lib/features/nueva_feature/
   ├── models/
   ├── providers/
   ├── screens/
   ├── services/
   └── widgets/
   ```

2. **Agregar Rutas**
   - Actualizar `lib/main.dart`
   - Crear constantes en `lib/core/constants/routes.dart`

3. **Implementar Providers**
   - Crear nuevo provider
   - Registrar en `MultiProvider`

### 2. Modificar Feature Existente

1. **Localizar Archivos**
   - Identificar componentes afectados
   - Revisar dependencias

2. **Implementar Cambios**
   - Seguir patrones existentes
   - Mantener consistencia de estilo

3. **Actualizar Tests**
   - Modificar tests existentes
   - Agregar nuevos tests

## Estándares de Código

### 1. Nombrado

- **Clases**: PascalCase
  ```dart
  class TransportCube { }
  ```

- **Variables/Métodos**: camelCase
  ```dart
  void updateGuideState() { }
  final cubeState = 'active';
  ```

- **Constantes**: SCREAMING_SNAKE_CASE
  ```dart
  const API_BASE_URL = 'https://api.example.com';
  ```

### 2. Documentación

- **Clases**:
  ```dart
  /// Representa un cubo de transporte.
  ///
  /// Contiene la información y estado de un grupo de guías
  /// que se mueven juntas en el proceso logístico.
  class TransportCube { }
  ```

- **Métodos Públicos**:
  ```dart
  /// Actualiza el estado de las guías en el cubo.
  ///
  /// [newState] es el nuevo estado a aplicar.
  /// Retorna `true` si la actualización fue exitosa.
  Future<bool> updateGuides(String newState) async { }
  ```

### 3. Organización de Archivos

- Un widget por archivo
- Nombres de archivo en snake_case
- Sufijos descriptivos (_screen, _widget, _service)

## Testing

### 1. Unit Tests

```dart
void main() {
  group('TransportCube Tests', () {
    test('should update state correctly', () {
      final cube = TransportCube();
      cube.updateState('sent');
      expect(cube.state, equals('sent'));
    });
  });
}
```

### 2. Widget Tests

```dart
void main() {
  testWidgets('Counter increments smoke test', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('0'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
  });
}
```

## CI/CD

### 1. Pre-commit
Ejecutar antes de cada commit:
```bash
flutter analyze
flutter test
flutter format .
```

### 2. GitHub Actions
Pipeline incluye:
- Lint
- Tests
- Build
- Deploy (staging/prod)

## Despliegue

### 1. Android
```bash
flutter build apk --release
```

### 2. iOS
```bash
flutter build ios --release
```

### 3. Windows
```bash
flutter build windows --release
```

## Debugging

### 1. Logs
```dart
debugPrint('Estado actual: $state');
```

### 2. DevTools
1. Iniciar DevTools:
   ```bash
   flutter pub global run devtools
   ```
2. Conectar app en modo debug

### 3. Network
- Usar Network Inspector en DevTools
- Revisar logs en `HttpService`

## Resolución de Problemas

### Build Issues

1. **Limpieza de Cache**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Actualización de Dependencias**
   ```bash
   flutter pub upgrade
   ```

3. **Regenerar Archivos**
   ```bash
   flutter create . --platforms=android,ios,windows
   ```

### Runtime Issues

1. **Modo Debug**
   - Usar DevTools
   - Revisar logs
   - Verificar estado

2. **Network**
   - Verificar conectividad
   - Validar respuestas API
   - Revisar tokens

## Mejores Prácticas

1. **Control de Versiones**
   - Commits atómicos
   - Mensajes descriptivos
   - Pull requests documentados

2. **Código**
   - DRY (Don't Repeat Yourself)
   - SOLID principles
   - Clean Architecture

3. **UI/UX**
   - Material Design guidelines
   - Responsive design
   - Accesibilidad

## Recursos Adicionales

1. **Documentación**
   - [Flutter Dev](https://flutter.dev/docs)
   - [Dart Dev](https://dart.dev/guides)
   - [Material Design](https://material.io/design)

2. **Herramientas**
   - [Flutter DevTools](https://flutter.dev/docs/development/tools/devtools)
   - [Dart DevTools](https://dart.dev/tools/dart-devtools)

3. **Comunidad**
   - [Flutter GitHub](https://github.com/flutter/flutter)
   - [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)