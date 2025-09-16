import 'dart:convert';
import 'dart:developer' as developer;
import '../services/app_logger.dart';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import '../models/api_error.dart';

  /// Servicio base para peticiones HTTP
class HttpService {
  final String baseUrl;
  String? _token;
  Function()? onSessionExpired;

  /// Sanitiza el cuerpo para logs, removiendo 'message' y preservando 'messageDetail'
  /// Solo aplica para endpoints de despacho en aduana y creación/listado de cubos
  String _sanitizeBodyForLog(String url, String body) {
    try {
      final lower = url.toLowerCase();
      final isCubeEndpoint = lower.contains('/guide/new-transport-cube') ||
          lower.contains('/guide/get-transport-cubes');
      if (!isCubeEndpoint) return body;
      developer.debugger();
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
  });

  /// Establece el token de autenticación
  void setToken(String? token) {
    if (token == null) {
      _token = null;
      AppLogger.log('Token cleared', source: 'HttpService');
      return;
    }

    // Asegurar formato correcto del token
    _token = token.startsWith('Bearer ') ? token : 'Bearer $token';
    AppLogger.log('Token set: $_token', source: 'HttpService', type: 'AUTH');
  }

  /// Obtiene los headers comunes para las peticiones
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': (_token!.startsWith('Bearer ') ? _token! : 'Bearer $_token!'),
  };

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
      AppLogger.apiCall(
        uri.toString(),
        method: 'GET',
      );
      final sanitizedBody = _sanitizeBodyForLog(uri.toString(), response.body);
      AppLogger.apiResponse(
        uri.toString(),
        statusCode: response.statusCode,
        body: sanitizedBody,
      );

      if (response.statusCode == 401) {
        AppLogger.error(
          'Received 401 Unauthorized response',
          source: 'HttpService',
          error: 'Session expired',
        );
        final error = ApiError.sessionExpired();
        
        // Solo limpiar token y llamar a onSessionExpired si no se suprime el manejo de auth
        if (!suppressAuthHandling) {
          _token = null;
          onSessionExpired?.call();
        } else {
          AppLogger.log(
            'Skipping token cleanup due to suppressAuthHandling',
            source: 'HttpService'
          );
        }
        
        return ApiResponse.error(
          messageDetail: error.userMessage,
          content: null,
        );
      }

      Map<String, dynamic> json;
      try {
        json = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return ApiResponse.error(message: ApiError.serverError('Respuesta inválida del servidor').userMessage);
      }

      final code = json['code'] as int? ?? ApiErrorCode.SERVER_ERROR;
      final message = json['message'] as String? ?? '';
      final messageDetail = json['messageDetail'] as String?;

      // Si el backend respondió sesión expirada en el body
      if (code == ApiErrorCode.SESSION_EXPIRED || code == ApiErrorCode.INVALID_TOKEN) {
        if (!suppressAuthHandling) {
        developer.log('Auth error in body code ($code): $messageDetail', name: 'HttpService');
        
        // Solo limpiar token y llamar a onSessionExpired si no se suprime el manejo de auth
        if (!suppressAuthHandling) {
          _token = null;
          await Future(() {
            onSessionExpired?.call();
          });
        } else {
          AppLogger.log(
            'Skipping token cleanup due to suppressAuthHandling',
            source: 'HttpService'
          );
        }
        
          return ApiResponse.error(message: ApiError.sessionExpired().userMessage);
        } else {
          // Si se suprime el manejo de auth, retornar el error pero no cerrar sesión
          AppLogger.log(
            'Returning error but keeping session due to suppressAuthHandling',
            source: 'HttpService'
          );
          return ApiResponse.error(
            message: json['message'] ?? 'Error de autenticación',
            content: null,
          );
        }
      }

      // Si el código no es 0 (éxito) o 1 (warning), es un error
      if (code > 1) {
        final error = ApiError(code: code, message: messageDetail ?? '');
        return ApiResponse.error(message: error.userMessage);
      }

      // Aquí ya sabemos que la respuesta es exitosa
      final defaultMessage = message == 'Su transacción fue realizada con éxito (0)' ? null : message;
      return ApiResponse(
        isSuccessful: true,
        message: messageDetail ?? defaultMessage,
        messageDetail: messageDetail,
        content: fromJson(json),
      );
    } catch (e) {
      final error = _handleError(e);
      developer.log('Error en GET request: ${error.message}', name: 'HttpService', error: e);
      return ApiResponse.error(message: error.userMessage);
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

      if (response.statusCode == 401) {
        developer.log('Authentication error: 401 Unauthorized', name: 'HttpService');
        final error = ApiError.sessionExpired();
        if (!suppressAuthHandling) {
          onSessionExpired?.call();
        }
        return ApiResponse.error(
          message: error.userMessage,
          content: null,
        );
      }

      Map<String, dynamic> json;
      try {
        json = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return ApiResponse.error(message: ApiError.serverError('Respuesta inválida del servidor').userMessage);
      }

      final code = json['code'] as int? ?? ApiErrorCode.SERVER_ERROR;
      final message = json['message'] as String? ?? '';
      final messageDetail = json['messageDetail'] as String?;

      // Manejar código especial (60): tratar como éxito PERO conservar el contenido del backend
      if (message.contains('(60)')) {
        return ApiResponse(
          isSuccessful: true,
          message: message,
          content: fromJson(json),
        );
      }

      // Si el backend respondió sesión expirada en el body
      if (code == ApiErrorCode.SESSION_EXPIRED || code == ApiErrorCode.INVALID_TOKEN) {
        if (!suppressAuthHandling) {
        developer.log('Auth error detected: $message', name: 'HttpService');
        
        if (!suppressAuthHandling) {
          _token = null;
          await Future(() {
            onSessionExpired?.call();
          });
          return ApiResponse.error(message: ApiError.sessionExpired().userMessage);
        }

        } else {
          // Si se suprime el manejo de auth, retornar el error pero no cerrar sesión
          AppLogger.log(
            'Returning error but keeping session due to suppressAuthHandling',
            source: 'HttpService'
          );
          return ApiResponse.error(
            message: json['message'] ?? 'Error de autenticación',
            content: null,
          );
        }
      }

      // Si el código no es 0 (éxito) o 1 (warning), es un error
      if (code > 1) {
        final error = ApiError(code: code, message: messageDetail ?? message);
        return ApiResponse.error(message: error.userMessage);
      }

      // Aquí ya sabemos que la respuesta es exitosa
      final defaultMessage = message == 'Su transacción fue realizada con éxito (0)' ? null : message;
      return ApiResponse(
        isSuccessful: true,
        message: messageDetail ?? defaultMessage,
        messageDetail: messageDetail,
        content: fromJson != null ? fromJson(json) : null,
      );
    } catch (e) {
      final error = _handleError(e);
      developer.log('Error en POST request: ${error.message}', name: 'HttpService', error: e);
      return ApiResponse.error(message: error.userMessage);
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

      if (response.statusCode == 401) {
        developer.log('Authentication error: 401 Unauthorized', name: 'HttpService');
        final error = ApiError.sessionExpired();
        if (!suppressAuthHandling) {
          _token = null; // Limpiar token inválido
          await Future(() {
            onSessionExpired?.call(); // Llamar en el siguiente frame
          });
        }
        return ApiResponse.error(
          message: error.userMessage,
          content: null,
        );
      }

      Map<String, dynamic> json;
      try {
        json = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return ApiResponse.error(message: ApiError.serverError('Respuesta inválida del servidor').userMessage);
      }

      final code = json['code'] as int? ?? ApiErrorCode.SERVER_ERROR;
      final message = json['message'] as String? ?? '';
      final messageDetail = json['messageDetail'] as String?;

      // Si el código no es 0 (éxito) o 1 (warning), es un error
      if (code > 1) {
        final error = ApiError(code: code, message: messageDetail ?? message);
        developer.log(
          'API Error:\n- Code: $code\n- Message: $message\n- Detail: $messageDetail',
          name: 'HttpService',
          error: error,
        );
        return ApiResponse.error(message: error.userMessage);
      }

      // Aquí ya sabemos que la respuesta es exitosa
      return ApiResponse(
        isSuccessful: true,
        message: messageDetail ?? message,
        content: fromJson != null ? fromJson(json) : null,
      );
    } catch (e) {
      final error = _handleError(e);
      developer.log('Error en PUT request: ${error.message}', name: 'HttpService', error: e);
      return ApiResponse.error(message: error.userMessage);
    }
  }

  /// Maneja errores comunes y los convierte en ApiError
  ApiError _handleError(Object e) {
    developer.log('Error HTTP: $e', name: 'HttpService');
    
    if (e is SocketException) {
      return ApiError(
        code: ApiErrorCode.NETWORK_ERROR,
        message: 'Error de conexión: ${e.message}',
      );
    }
    
    if (e is TimeoutException) {
      return ApiError(
        code: ApiErrorCode.TIMEOUT,
        message: 'La solicitud ha tardado demasiado tiempo',
      );
    }
    
    if (e is FormatException) {
      return ApiError(
        code: ApiErrorCode.SERVER_ERROR,
        message: 'Error al procesar la respuesta del servidor',
      );
    }
    
    return ApiError(
      code: ApiErrorCode.UNKNOWN,
      message: e.toString(),
    );
  }
}
