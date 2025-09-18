# API Documentation - GBI Logistics

## Autenticación

### Endpoints

#### Login
```
POST /api/auth/login
```

**Request Body:**
```json
{
  "username": "string",
  "password": "string"
}
```

**Response:**
```json
{
  "access_token": "string",
  "refresh_token": "string",
  "expires_in": "number"
}
```

#### Refresh Token
```
POST /api/auth/refresh
```

**Request Body:**
```json
{
  "refresh_token": "string"
}
```

**Response:**
```json
{
  "access_token": "string",
  "refresh_token": "string",
  "expires_in": "number"
}
```

## Guías

### Endpoints

#### Listar Guías
```
GET /api/guides
```

**Query Parameters:**
- `state`: Estado de la guía (opcional)
- `page`: Número de página (por defecto: 1)
- `limit`: Límite por página (por defecto: 20)

**Response:**
```json
{
  "items": [
    {
      "id": "number",
      "tracking_number": "string",
      "state": "string",
      "register_date": "datetime",
      "current_location": "string"
    }
  ],
  "total": "number",
  "page": "number",
  "limit": "number"
}
```

#### Detalles de Guía
```
GET /api/guides/{id}
```

**Response:**
```json
{
  "id": "number",
  "tracking_number": "string",
  "state": "string",
  "register_date": "datetime",
  "current_location": "string",
  "history": [
    {
      "state": "string",
      "location": "string",
      "timestamp": "datetime"
    }
  ]
}
```

## Cubos de Transporte

### Endpoints

#### Listar Cubos
```
GET /api/transport-cubes
```

**Query Parameters:**
- `state`: Estado del cubo (opcional)
- `page`: Número de página (por defecto: 1)
- `limit`: Límite por página (por defecto: 20)

**Response:**
```json
{
  "items": [
    {
      "id": "number",
      "state": "string",
      "register_date_time": "datetime",
      "guides": "number"
    }
  ],
  "total": "number",
  "page": "number",
  "limit": "number"
}
```

#### Crear Cubo
```
POST /api/transport-cubes
```

**Request Body:**
```json
{
  "guide_ids": ["number"]
}
```

**Response:**
```json
{
  "id": "number",
  "state": "string",
  "register_date_time": "datetime",
  "guides": "number"
}
```

#### Detalles de Cubo
```
GET /api/transport-cubes/{id}
```

**Response:**
```json
{
  "id": "number",
  "state": "string",
  "register_date_time": "datetime",
  "guides": [
    {
      "id": "number",
      "tracking_number": "string",
      "state": "string"
    }
  ]
}
```

#### Actualizar Estado de Cubo
```
PUT /api/transport-cubes/{id}/state
```

**Request Body:**
```json
{
  "state": "string"
}
```

**Response:**
```json
{
  "id": "number",
  "state": "string",
  "register_date_time": "datetime",
  "guides": "number"
}
```

## Modelos

### Guide (Guía)

```dart
class Guide {
  final int id;
  final String trackingNumber;
  final String state;
  final DateTime registerDate;
  final String currentLocation;
  final List<GuideHistory>? history;
}

class GuideHistory {
  final String state;
  final String location;
  final DateTime timestamp;
}
```

### TransportCube (Cubo de Transporte)

```dart
class TransportCube {
  final int id;
  final String state;
  final DateTime registerDateTime;
  final List<Guide>? guides;
}

class TransportCubeInfo {
  final int id;
  final String state;
  final DateTime registerDateTime;
  final int guides;
}
```

## Estados

### Estados de Guía
- `ReceivedInLocalWarehouse`: Recibido en Bodega Local

### Estados de Cubo
- `Created`: Creado (UI: "Despachado de Aduana")
- `Sent`: Enviado (UI: "Tránsito a Bodega")
- `Downloading`: Descargando (UI: "Recibido en Bodega Local")
- `Downloaded`: Descargado (UI: "Listo para Entrega")

## Integración

### HttpService

El servicio base para comunicación HTTP maneja:

1. **Autenticación**
   - Adjunta token de acceso a cada request
   - Maneja refresh automático de tokens
   - Intercepta errores de autenticación

2. **Manejo de Errores**
   - Errores de red
   - Errores de API
   - Errores de autenticación

3. **Interceptores**
   - Logging de requests/responses
   - Transformación de datos
   - Manejo de estados HTTP

### Ejemplo de Uso

```dart
class GuideService {
  final HttpService _http;

  Future<List<Guide>> getGuides({String? state}) async {
    final response = await _http.get(
      '/api/guides',
      queryParameters: {'state': state},
    );
    
    return (response.data['items'] as List)
        .map((item) => Guide.fromJson(item))
        .toList();
  }
}
```

## Consideraciones

### Rate Limiting
- Límite de 100 requests por minuto por usuario
- Headers de rate limit incluidos en respuestas
- Backoff exponencial recomendado

### Caché
- Cache-Control headers en respuestas
- ETags para validación
- Cache client-side recomendado

### Seguridad
- HTTPS requerido
- Tokens JWT
- CORS configurado
- API Keys para clientes externos