# Documentación de Componentes - GBI Logistics

## Componentes Core

### GuideCounter

Widget que muestra un contador de guías con su estado actual.

```dart
GuideCounter(
  count: 5,
  state: GuideState.received,
  onTap: () => handleTap(),
)
```

**Propiedades:**
- `count`: Número de guías
- `state`: Estado actual de las guías
- `onTap`: Callback para manejo de tap (opcional)

**Uso típico:**
```dart
Column(
  children: [
    Text('Guías en Bodega'),
    GuideCounter(
      count: cubeGuides.length,
      state: GuideState.receivedInLocalWarehouse,
    ),
  ],
)
```

### GuideStatusIndicator

Indicador visual del estado actual de una guía.

```dart
GuideStatusIndicator(
  state: guide.state,
  showLabel: true,
)
```

**Propiedades:**
- `state`: Estado de la guía
- `showLabel`: Mostrar texto del estado (default: true)
- `size`: Tamaño del indicador (default: 24.0)

**Estilos por Estado:**
- `Created`: Azul
- `Sent`: Naranja
- `Downloading`: Amarillo
- `Downloaded`: Verde

### StateFilter

Filtro de estados para listas de guías o cubos.

```dart
StateFilter<GuideState>(
  states: GuideState.values,
  selectedState: currentState,
  onStateChanged: (state) => updateState(state),
)
```

**Propiedades:**
- `states`: Lista de estados disponibles
- `selectedState`: Estado actualmente seleccionado
- `onStateChanged`: Callback de cambio de estado

## Componentes de Feature Logistics

### TransportCubeCard

Tarjeta que muestra información de un cubo de transporte.

```dart
TransportCubeCard(
  cube: transportCube,
  onTap: () => navigateToDetails(cube.id),
)
```

**Propiedades:**
- `cube`: Modelo TransportCube
- `onTap`: Callback de tap
- `selected`: Estado de selección (opcional)

**Layout:**
```
┌─────────────────────────┐
│ ID: #123               ▲│
│ Estado: En Tránsito     │
│ Guías: 5               ▼│
└─────────────────────────┘
```

### GuideList

Lista de guías con funcionalidad de selección.

```dart
GuideList(
  guides: availableGuides,
  selectedGuides: selectedGuides,
  onGuideSelected: (guide) => toggleGuide(guide),
)
```

**Propiedades:**
- `guides`: Lista de guías
- `selectedGuides`: Guías seleccionadas
- `onGuideSelected`: Callback de selección
- `showCheckbox`: Mostrar checkbox (default: true)

### ScannerView

Componente para escaneo de códigos de barras/QR.

```dart
ScannerView(
  onCodeScanned: (code) => processCode(code),
  allowMultiple: true,
)
```

**Propiedades:**
- `onCodeScanned`: Callback de escaneo
- `allowMultiple`: Permitir escaneos múltiples
- `formats`: Formatos permitidos (default: todos)

## Screens

### CustomsDispatchScreen

Pantalla principal de despacho aduanero.

**Componentes clave:**
```dart
class CustomsDispatchScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Despacho Aduanero')),
      body: Column(
        children: [
          StateFilter<CubeState>(...),
          Expanded(
            child: TransportCubeList(...),
          ),
          BottomActionBar(...),
        ],
      ),
    );
  }
}
```

### WarehouseReceptionScreen

Pantalla de recepción en bodega.

**Componentes clave:**
```dart
class WarehouseReceptionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Recepción en Bodega')),
      body: Column(
        children: [
          ScannerView(...),
          GuideList(...),
          BottomActionBar(...),
        ],
      ),
    );
  }
}
```

## Widgets Compartidos

### BottomActionBar

Barra de acciones inferior.

```dart
BottomActionBar(
  primaryAction: ActionButton(
    label: 'Continuar',
    onPressed: () => handleContinue(),
  ),
  secondaryAction: ActionButton(
    label: 'Cancelar',
    onPressed: () => handleCancel(),
  ),
)
```

**Propiedades:**
- `primaryAction`: Acción principal
- `secondaryAction`: Acción secundaria (opcional)
- `loading`: Estado de carga

### ActionButton

Botón de acción estándar.

```dart
ActionButton(
  label: 'Enviar',
  onPressed: () => handleSend(),
  icon: Icons.send,
)
```

**Propiedades:**
- `label`: Texto del botón
- `onPressed`: Callback de presión
- `icon`: Icono (opcional)
- `loading`: Estado de carga

### ErrorView

Vista de error con retry.

```dart
ErrorView(
  message: 'Error de conexión',
  onRetry: () => retryOperation(),
)
```

**Propiedades:**
- `message`: Mensaje de error
- `onRetry`: Callback de retry (opcional)
- `icon`: Icono personalizado (opcional)

## Temas y Estilos

### Colores

```dart
class AppColors {
  static const primary = Color(0xFF1976D2);
  static const secondary = Color(0xFF26A69A);
  static const error = Color(0xFFD32F2F);
  static const warning = Color(0xFFFFA000);
  static const success = Color(0xFF388E3C);
}
```

### TextStyles

```dart
class AppTextStyles {
  static const headline1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );
  
  static const body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );
}
```

## Estados y Feedback

### LoadingOverlay

Overlay de carga con indicador de progreso.

```dart
LoadingOverlay(
  isLoading: true,
  child: YourWidget(),
)
```

**Propiedades:**
- `isLoading`: Estado de carga
- `child`: Widget hijo
- `message`: Mensaje de carga (opcional)

### StatusSnackbar

Snackbar para mensajes de estado.

```dart
StatusSnackbar.show(
  context: context,
  message: 'Operación exitosa',
  type: SnackbarType.success,
)
```

**Tipos:**
- `success`
- `error`
- `warning`
- `info`

## Mejores Prácticas

### 1. Composición

- Preferir composición sobre herencia
- Mantener widgets pequeños y enfocados
- Extraer lógica compleja a providers

### 2. Reutilización

- Crear widgets base reutilizables
- Mantener consistencia en props
- Documentar casos de uso

### 3. Performance

- Usar `const` constructors
- Implementar `shouldRebuild`
- Minimizar rebuilds innecesarios

### 4. Accesibilidad

- Incluir labels para screen readers
- Mantener contraste adecuado
- Soportar navegación por teclado

## Ejemplos de Implementación

### 1. Lista con Selección

```dart
class SelectableList extends StatelessWidget {
  final List<Item> items;
  final Set<Item> selected;
  final ValueChanged<Item> onToggle;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return SelectableItem(
          item: item,
          selected: selected.contains(item),
          onToggle: () => onToggle(item),
        );
      },
    );
  }
}
```

### 2. Form con Validación

```dart
class ValidatedForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            validator: (value) => validateField(value),
          ),
          ActionButton(
            label: 'Enviar',
            onPressed: () {
              if (formKey.currentState!.validate()) {
                onSubmit();
              }
            },
          ),
        ],
      ),
    );
  }
}
```

## Testing de Componentes

### 1. Widget Tests

```dart
testWidgets('GuideCounter shows correct count', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: GuideCounter(
        count: 5,
        state: GuideState.received,
      ),
    ),
  );

  expect(find.text('5'), findsOneWidget);
});
```

### 2. Golden Tests

```dart
testWidgets('TransportCubeCard matches golden', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: TransportCubeCard(
        cube: sampleCube,
      ),
    ),
  );

  await expectLater(
    find.byType(TransportCubeCard),
    matchesGoldenFile('transport_cube_card.png'),
  );
});
```