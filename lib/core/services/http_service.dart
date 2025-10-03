import 'dart:convert';
import 'dart:developer' as developer;
import '../services/app_logger.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import '../models/api_error.dart';
import 'version_service.dart';

/// Servicio base para peticiones HTTP
class HttpService {
  final String baseUrl;
  String? _token;
  Function()? onSessionExpired;
  Function()? onTokenRefreshNeeded;
  bool _isHandlingExpiredSession = false;
  Function(VersionResponse)? onVersionCheckRequired;

  /// Callback para refrescar el token cuando sea necesario
  Function()? get tokenRefreshCallback => onTokenRefreshNeeded;
  set tokenRefreshCallback(Function()? callback) {
    onTokenRefreshNeeded = callback;
  }

  /// Callback para manejar actualizaciones de versión requeridas
  set versionCheckCallback(Function(VersionResponse)? callback) {
    onVersionCheckRequired = callback;
  }

  /// Sanitiza el cuerpo para logs, removiendo 'message' y preservando 'messageDetail'
  /// Solo aplica para endpoints de despacho en aduana y creación/listado de cubos
  String _sanitizeBodyForLog(String url, String body) {
    try {
      final lower = url.toLowerCase();
      final isCubeEndpoint = lower.contains('/guide/new-transport-cube') ||
          lower.contains('/guide/get-transport-cubes');
      if (!isCubeEndpoint) return body;
      final dynamic parsed = jsonDecode(body);
      if (parsed is Map<String, dynamic>) {
        // Eliminar message y usar solo messageDetail
        parsed.remove('message');
        final String? md = parsed['messageDetail'] as String?;
        if (md == null || md.isEmpty) {
          parsed.remove('messageDetail');
        }
        return jsonEncode(parsed);
      }
      return body;
    } catch (_) {
      return body; // En caso de error, no romper logs
    }
  }

  HttpService({
    required this.baseUrl,
    this.onSessionExpired,
    this.onTokenRefreshNeeded,
  });

  /// Establece el token de autenticación
  void setToken(String? token) {
    if (token == null || token.trim().isEmpty) {
      _token = null;
      AppLogger.log('Token cleared', source: 'HttpService');
      return;
    }

    // Asegurar formato correcto del token
    _token = token.startsWith('Bearer ') ? token : 'Bearer $token';
    AppLogger.log('Token set: $_token', source: 'HttpService', type: 'AUTH');
      _isHandlingExpiredSession = false; // Resetear flag al establecer nuevo token
  }

  /// Verifica los headers de respuesta para detectar requerimientos de actualización
  void _checkVersionHeaders(Map<String, String> responseHeaders) {
    try {
      final versionResponse = VersionResponse.fromHeaders(responseHeaders);
      
      if (versionResponse.updateRequired || versionResponse.updateAvailable) {
        AppLogger.log(
          'Version check response: updateRequired=${versionResponse.updateRequired}, '
          'updateAvailable=${versionResponse.updateAvailable}, '
          'minVersion=${versionResponse.minVersion}',
          source: 'HttpService'
        );
        
        onVersionCheckRequired?.call(versionResponse);
      }
    } catch (e) {
      // Error procesando headers de versión, continuar normalmente
      AppLogger.log(
        'Error checking version headers: $e',
        source: 'HttpService'
      );
    }
  }

  /// Obtiene los headers comunes para las peticiones
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': _token!,
    ...VersionService.instance.versionHeaders,
  };

  /// Maneja una respuesta 401 o error de sesión
  Future<void> _handleSessionExpired({
    bool suppressAuthHandling = false,
    String? message,
    String? messageDetail,
  }) async {
    if (_isHandlingExpiredSession) {
      AppLogger.log(
        'Session expired handling already in progress, skipping',
        source: 'HttpService'
      );
      return;
    }

    _isHandlingExpiredSession = true;

    if (!suppressAuthHandling) {
      _token = null;
      
      if (onSessionExpired != null) {
        AppLogger.log(
          'Calling onSessionExpired callback',
          source: 'HttpService'
        );
        await Future(() => onSessionExpired!());
      }
    } else {
      AppLogger.log(
        'Skipping session expired handling due to suppressAuthHandling',
        source: 'HttpService'
      );
    }
  }

  /// Realiza una petición GET
  Future<ApiResponse<T>> get<T>(
    String path,
    T Function(Map<String, dynamic> json) fromJson, {
    Map<String, dynamic>? queryParams,
    bool suppressAuthHandling = false,
  }) async {
    try {
      final uri = Uri.parse(baseUrl + path).replace(
        queryParameters: queryParams?.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );
      
      AppLogger.log(
        'Making GET request to: ${uri.toString()}\nParams: $queryParams',
        source: 'HttpService'
      );

      final client = http.Client();
      final response = await client.get(uri, headers: _headers)
        .timeout(const Duration(seconds: 30));

      AppLogger.apiCall(uri.toString(), method: 'GET');
      
      final sanitizedBody = _sanitizeBodyForLog(uri.toString(), response.body);
      AppLogger.apiResponse(
        uri.toString(),
        statusCode: response.statusCode,
        body: sanitizedBody,
      );

      // Verificar headers de versión
      _checkVersionHeaders(response.headers);

      Map<String, dynamic> json;
      String? messageDetail;
      String message = '';
      int code = ApiErrorCode.unknown;
      
      if (response.statusCode == 401) {
        AppLogger.error(
          'Received 401 Unauthorized response',
          source: 'HttpService',
          error: 'Session expired',
        );

        // Intentar parsear el body para obtener messageDetail del backend
        try {
          json = jsonDecode(response.body) as Map<String, dynamic>;
          messageDetail = json['messageDetail'] as String?;
        } catch (_) {
          // Si no se puede parsear, usar null
        }

        await _handleSessionExpired(
          suppressAuthHandling: suppressAuthHandling,
          messageDetail: messageDetail,
        );

        return ApiResponse.error(
          messageDetail: messageDetail, // Usar messageDetail del backend si existe
          content: null,
        );
      }

      try {
        json = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return ApiResponse.error(
          messageDetail: response.body,
          content: null
        );
      }

      code = json['code'] as int? ?? ApiErrorCode.unknown;
      message = json['message'] as String? ?? '';
      messageDetail = json['messageDetail'] as String?;

      // Si el backend respondió sesión expirada en el body
if (code == ApiErrorCode.sessionExpired || code == ApiErrorCode.invalidToken) {
        await _handleSessionExpired(
          suppressAuthHandling: suppressAuthHandling,
          message: message,
          messageDetail: messageDetail,
        );

        return ApiResponse.error(
          messageDetail: messageDetail,
          content: null,
        );
      }

      // Si el código no es 0 (éxito) o 1 (warning), es un error
      if (code > 1) {
        final error = ApiError(code: code, message: messageDetail ?? message);
        return ApiResponse.error(messageDetail: error.userMessage);
      }

      // Aquí ya sabemos que la respuesta es exitosa
      final mDetail = message == 'Su transacción fue realizada con éxito (0)'
          ? message // Usar el mensaje genérico como messageDetail
          : messageDetail;
      
      return ApiResponse(
        isSuccessful: true,
        message: null, // No usar message para mensajes de éxito
        messageDetail: mDetail,
        content: fromJson(json),
      );
    } catch (e) {
      AppLogger.error('Error en GET request', error: e, source: 'HttpService');
      final error = ApiError(
        code: e is TimeoutException ? ApiErrorCode.timeout : ApiErrorCode.networkError,
        message: e.toString(),
      );
      return ApiResponse.error(messageDetail: error.userMessage);
    }
  }

  /// Realiza una petición POST
  Future<ApiResponse<T>> post<T>(
    String path,
    dynamic data,
    T Function(Map<String, dynamic> json) fromJson, {
    bool suppressAuthHandling = false,
  }) async {
    AppLogger.log(
      'HTTP POST Request:\n'
      'URL: $baseUrl$path\n'
      'Headers: $_headers\n'
      'Body: ${jsonEncode(data)}',
      source: 'HttpService'
    );

    try {
      final client = http.Client();
      final response = await client.post(
        Uri.parse(baseUrl + path),
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30));

      developer.log('Response Status: ${response.statusCode}', name: 'HttpService');
      final sanitizedBody = _sanitizeBodyForLog(baseUrl + path, response.body);
      developer.log('Response Body: $sanitizedBody', name: 'HttpService');

      // Verificar headers de versión
      _checkVersionHeaders(response.headers);

      Map<String, dynamic> json;
      String? messageDetail;
      String message = '';
      int code = ApiErrorCode.unknown;
      
      if (response.statusCode == 401) {
        AppLogger.error(
          'Authentication error: 401 Unauthorized',
          source: 'HttpService',
          error: 'Session expired',
        );

        // Intentar parsear el body para obtener messageDetail del backend
        try {
          json = jsonDecode(response.body) as Map<String, dynamic>;
          messageDetail = json['messageDetail'] as String?;
        } catch (_) {
          // Si no se puede parsear, usar null
        }

        await _handleSessionExpired(
          suppressAuthHandling: suppressAuthHandling,
          messageDetail: messageDetail,
        );

        return ApiResponse.error(
          messageDetail: messageDetail, // Usar messageDetail del backend si existe
          content: null,
        );
      }

      try {
        json = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        // NO generar mensaje nosotros, dejar que el backend lo proporcione
        return ApiResponse.error(
          messageDetail: null,
        );
      }

      code = json['code'] as int? ?? ApiErrorCode.unknown;
      message = json['message'] as String? ?? '';
      messageDetail = json['messageDetail'] as String?;

      // Manejar código especial (60): tratar como éxito PERO conservar el contenido del backend
      if (message.contains('(60)')) {
        return ApiResponse(
          isSuccessful: true,
          message: message,
          messageDetail: messageDetail,
          content: fromJson(json),
        );
      }

      // Si el backend respondió sesión expirada en el body
if (code == ApiErrorCode.sessionExpired || code == ApiErrorCode.invalidToken) {
        await _handleSessionExpired(
          suppressAuthHandling: suppressAuthHandling,
          message: message,
          messageDetail: messageDetail,
        );

        return ApiResponse.error(
          messageDetail: messageDetail ?? '',  // Use backend message
          content: null,
        );
      }

      // Si el código no es 0 (éxito) o 1 (warning), es un error
      if (code > 1) {
        return ApiResponse.error(
          messageDetail: messageDetail ?? ''  // Use backend message
        );
      }

      // Aquí ya sabemos que la respuesta es exitosa
      return ApiResponse(
        isSuccessful: true,
        message: null,  // No usar message para mensajes de éxito
        messageDetail: messageDetail,
        content: fromJson(json),
      );
    } catch (e) {
      AppLogger.error('Error en POST request', error: e, source: 'HttpService');
      final error = ApiError(
        code: e is TimeoutException ? ApiErrorCode.timeout : ApiErrorCode.networkError,
        message: e.toString(),
      );
      return ApiResponse.error(messageDetail: error.userMessage);
    }
  }

  /// Realiza una petición PUT
  Future<ApiResponse<T>> put<T>(
    String path,
    dynamic data,
    T Function(Map<String, dynamic> json)? fromJson, {
    bool suppressAuthHandling = false,
  }) async {
    developer.log('HTTP PUT Request', name: 'HttpService');
    developer.log('URL: $baseUrl$path', name: 'HttpService');
    developer.log('Headers: $_headers', name: 'HttpService');
    developer.log('Body: ${jsonEncode(data)}', name: 'HttpService');

    try {
      final client = http.Client();
      final response = await client.put(
        Uri.parse(baseUrl + path),
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30));

      developer.log('Response Status: ${response.statusCode}', name: 'HttpService');
      developer.log('Response Body: ${response.body}', name: 'HttpService');

      Map<String, dynamic> json;
      String? messageDetail;
      String message = '';
      int code = ApiErrorCode.unknown;
      
      if (response.statusCode == 401) {
        AppLogger.error(
          'Authentication error: 401 Unauthorized',
          source: 'HttpService',
          error: 'Session expired',
        );

        // Intentar parsear el body para obtener messageDetail del backend
        try {
          json = jsonDecode(response.body) as Map<String, dynamic>;
          messageDetail = json['messageDetail'] as String?;
        } catch (_) {
          // Si no se puede parsear, usar null
        }

        await _handleSessionExpired(
          suppressAuthHandling: suppressAuthHandling,
          messageDetail: messageDetail,
        );
        
        return ApiResponse.error(
          messageDetail: messageDetail, // Usar messageDetail del backend si existe
          content: null,
        );
      }

      try {
        json = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return ApiResponse.error(
          messageDetail: null // No generar mensaje, dejar que el backend lo proporcione
        );
      }

      code = json['code'] as int? ?? ApiErrorCode.unknown;
      message = json['message'] as String? ?? '';
      messageDetail = json['messageDetail'] as String?;

      // Si el código no es 0 (éxito) o 1 (warning), es un error
      if (code > 1) {
        final error = ApiError(code: code, message: messageDetail ?? message);
        developer.log(
          'API Error:\n- Code: $code\n- Message: $message\n- Detail: $messageDetail',
          name: 'HttpService',
          error: error,
        );
        return ApiResponse.error(messageDetail: error.userMessage);
      }

      // Aquí ya sabemos que la respuesta es exitosa
      // Si el mensaje es el de éxito por defecto, moverlo a messageDetail
      final mDetail = message == 'Su transacción fue realizada con éxito (0)'
          ? message // Usar el mensaje genérico como messageDetail
          : messageDetail;
      
      return ApiResponse(
        isSuccessful: true,
        message: null, // No usar message para mensajes de éxito
        messageDetail: mDetail,
        content: fromJson != null ? fromJson(json) : null,
      );
    } catch (e) {
      AppLogger.error('Error en PUT request', error: e, source: 'HttpService');
      final error = ApiError(
        code: e is TimeoutException ? ApiErrorCode.timeout : ApiErrorCode.networkError,
        message: e.toString(),
      );
      return ApiResponse.error(messageDetail: error.userMessage);
    }
  }
}