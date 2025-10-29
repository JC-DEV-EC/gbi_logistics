import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

import '../models/api_error.dart';
import '../models/api_response.dart';
import '../services/app_logger.dart';
import 'version_service.dart';

/// Servicio base para peticiones HTTP
class HttpService {
  final String baseUrl;
  String? _token;

  // Callbacks
  Function()? onSessionExpired;
  Future<bool> Function()? onTokenRefreshNeeded;
  Function(VersionResponse)? onVersionCheckRequired;

  bool _isHandlingExpiredSession = false;

  /// Callback para refrescar el token cuando sea necesario
  Future<bool> Function()? get tokenRefreshCallback => onTokenRefreshNeeded;
  set tokenRefreshCallback(Future<bool> Function()? callback) {
    onTokenRefreshNeeded = callback;
  }

  /// Callback para manejar actualizaciones de versión requeridas
  set versionCheckCallback(Function(VersionResponse)? callback) {
    onVersionCheckRequired = callback;
  }

  HttpService({
    required this.baseUrl,
    this.onSessionExpired,
    this.onTokenRefreshNeeded,
  });

  // -----------------------------
  // Token & Headers
  // -----------------------------
  void setToken(String? token) {
    if (token == null || token.trim().isEmpty) {
      _token = null;
      AppLogger.log('Token cleared', source: 'HttpService');
      return;
    }

    _token = token.startsWith('Bearer ') ? token : 'Bearer $token';
    AppLogger.log('Token set: $_token', source: 'HttpService', type: 'AUTH');

    _isHandlingExpiredSession = false;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': _token!,
    ...VersionService.instance.versionHeaders,
  };

  // -----------------------------
  // Helpers
  // -----------------------------
  String _sanitizeBodyForLog(String url, String body) {
    try {
      final lower = url.toLowerCase();
      final isCubeEndpoint = lower.contains('/guide/new-transport-cube') ||
          lower.contains('/guide/get-transport-cubes');

      if (!isCubeEndpoint) return body;

      final dynamic parsed = jsonDecode(body);
      if (parsed is Map<String, dynamic>) {
        final String? msg = parsed['message'] as String?;
        final String? md = parsed['messageDetail'] as String?;

        if (msg == null || msg.isEmpty) parsed.remove('message');
        if (md == null || md.isEmpty) parsed.remove('messageDetail');

        return jsonEncode(parsed);
      }
      return body;
    } catch (_) {
      return body;
    }
  }

  void _checkVersionHeaders(Map<String, String> responseHeaders) {
    try {
      final versionResponse = VersionResponse.fromHeaders(responseHeaders);

      if (versionResponse.updateRequired || versionResponse.updateAvailable) {
        AppLogger.log(
          'Version check response: '
              'updateRequired=${versionResponse.updateRequired}, '
              'updateAvailable=${versionResponse.updateAvailable}, '
              'minVersion=${versionResponse.minVersion}',
          source: 'HttpService',
        );
        onVersionCheckRequired?.call(versionResponse);
      }
    } catch (e) {
      AppLogger.log('Error checking version headers: $e', source: 'HttpService');
    }
  }

  Future<bool> _attemptTokenRefresh() async {
    if (onTokenRefreshNeeded == null) return false;

    try {
      AppLogger.log('Attempting to refresh token', source: 'HttpService');
      return await onTokenRefreshNeeded!();
    } catch (e) {
      AppLogger.error('Error refreshing token', error: e, source: 'HttpService');
      return false;
    }
  }

  Future<void> _handleSessionExpired({
    bool suppressAuthHandling = false,
    String? messageDetail,
  }) async {
    if (suppressAuthHandling) {
      AppLogger.log(
        'Skipping session expired handling due to suppressAuthHandling',
        source: 'HttpService',
      );
      return;
    }

    if (_isHandlingExpiredSession) {
      AppLogger.log(
        'Session expired handling already in progress, skipping',
        source: 'HttpService',
      );
      return;
    }

    _isHandlingExpiredSession = true;
    try {
      _token = null;
      if (onSessionExpired != null) {
        AppLogger.log('Calling onSessionExpired callback',
            source: 'HttpService');
        await Future(() => onSessionExpired!());
      }
    } finally {
      _isHandlingExpiredSession = false;
    }
  }

  // -----------------------------
  // Métodos HTTP
  // -----------------------------

  /// GET
  Future<ApiResponse<T>> get<T>(
      String path,
      T Function(Map<String, dynamic> json) fromJson, {
        Map<String, dynamic>? queryParams,
        bool suppressAuthHandling = false,
      }) async {
    try {
      final uri = Uri.parse(baseUrl + path).replace(
        queryParameters:
        queryParams?.map((key, value) => MapEntry(key, value.toString())),
      );

      AppLogger.log(
        'Making GET request to: ${uri.toString()}\nParams: $queryParams',
        source: 'HttpService',
      );

      final client = http.Client();
      final response = await client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      AppLogger.apiCall(uri.toString(), method: 'GET');

      final sanitizedBody = _sanitizeBodyForLog(uri.toString(), response.body);
      AppLogger.apiResponse(
        uri.toString(),
        statusCode: response.statusCode,
        body: sanitizedBody,
      );

      _checkVersionHeaders(response.headers);

      if (response.statusCode == 503 || response.statusCode == 501) {
        return ApiResponse.error(
          messageDetail: 'Ocurrió un error en el servidor',
          content: null,
        );
      }

      if (response.statusCode == 401) {
        if (!_isHandlingExpiredSession && !suppressAuthHandling) {
          final refreshed = await _attemptTokenRefresh();
          if (refreshed) {
            return await get<T>(
              path,
              fromJson,
              queryParams: queryParams,
              suppressAuthHandling: true,
            );
          }
        }

        String? refreshedMessageDetail;
        try {
          final Map<String, dynamic> parsed401 = response.body.isNotEmpty
              ? (jsonDecode(response.body) as Map<String, dynamic>)
              : <String, dynamic>{};
          refreshedMessageDetail = parsed401['messageDetail'] as String?;
        } catch (_) {}

        await _handleSessionExpired(
          suppressAuthHandling: suppressAuthHandling,
          messageDetail: refreshedMessageDetail,
        );

        return ApiResponse.error(
          messageDetail: refreshedMessageDetail ?? 'Su sesión ha finalizado, por favor ingrese de nuevo',
          content: null,
        );
      }

      Map<String, dynamic> json;
      try {
        json = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return ApiResponse.error(messageDetail: response.body, content: null);
      }

      final int code = json['code'] as int? ?? ApiErrorCode.unknown;
      final String? message = json['message'] as String?;
      final String? messageDetail = json['messageDetail'] as String?;

      AppLogger.log(
        'Parsed GET response -> code: $code, message: ${message ?? ''}, messageDetail: ${messageDetail ?? ''}',
        source: 'HttpService',
      );

      if (code == ApiErrorCode.sessionExpired ||
          code == ApiErrorCode.invalidToken) {
        await _handleSessionExpired(
          suppressAuthHandling: suppressAuthHandling,
          messageDetail: messageDetail,
        );
        return ApiResponse.error(messageDetail: messageDetail, content: null);
      }

      if (code > 1) {
        final error = ApiError(code: code, message: messageDetail ?? '');
        return ApiResponse.error(messageDetail: error.userMessage);
      }

      return ApiResponse(
        isSuccessful: true,
        message: message,
        messageDetail: messageDetail,
        content: fromJson(json),
      );
    } catch (e) {
      AppLogger.error('Error en GET request', error: e, source: 'HttpService');
      final error = ApiError(
        code: e is TimeoutException
            ? ApiErrorCode.timeout
            : ApiErrorCode.networkError,
        message: e.toString(),
      );
      return ApiResponse.error(messageDetail: error.userMessage);
    }
  }

  /// POST
  Future<ApiResponse<T>> post<T>(
      String path,
      dynamic data,
      T Function(Map<String, dynamic> json) fromJson, {
        bool suppressAuthHandling = false,
      }) async {
    // Solo log para operaciones importantes (no refresh token ni validaciones)
    if (!path.contains('refresh-token') && !path.contains('check')) {
      AppLogger.log(
        'HTTP POST Request:\n'
            'URL: $baseUrl$path\n'
            'Headers: $_headers\n'
            'Body: ${jsonEncode(data)}',
        source: 'HttpService',
      );
    }

    try {
      if (!suppressAuthHandling && onTokenRefreshNeeded != null) {
        await onTokenRefreshNeeded!.call();
      }

      final client = http.Client();
      final response = await client
          .post(
        Uri.parse(baseUrl + path),
        headers: _headers,
        body: jsonEncode(data),
      )
          .timeout(const Duration(seconds: 30));

      developer.log('Response Status: ${response.statusCode}',
          name: 'HttpService');
      final sanitizedBody = _sanitizeBodyForLog(baseUrl + path, response.body);
      developer.log('Response Body: $sanitizedBody', name: 'HttpService');

      _checkVersionHeaders(response.headers);

      if (response.statusCode == 503 || response.statusCode == 501) {
        return ApiResponse.error(
          messageDetail: 'Ocurrió un error en el servidor',
          content: null,
        );
      }

      if (response.statusCode == 401) {
        String? refreshedMessageDetail;
        try {
          final Map<String, dynamic> parsed401 = response.body.isNotEmpty
              ? (jsonDecode(response.body) as Map<String, dynamic>)
              : <String, dynamic>{};
          refreshedMessageDetail = parsed401['messageDetail'] as String?;
        } catch (_) {}

        await _handleSessionExpired(
          suppressAuthHandling: suppressAuthHandling,
          messageDetail: refreshedMessageDetail,
        );

        return ApiResponse.error(
          messageDetail: refreshedMessageDetail ?? 'Su sesión ha finalizado, por favor ingrese de nuevo',
          content: null,
        );
      }

      Map<String, dynamic> json;
      try {
        json = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return ApiResponse.error(messageDetail: null, content: null);
      }

      final int code = json['code'] as int? ?? ApiErrorCode.unknown;
      final String? message = json['message'] as String?;
      final String? messageDetail = json['messageDetail'] as String?;

      AppLogger.log(
        'Parsed POST response -> code: $code, message: ${message ?? ''}, messageDetail: ${messageDetail ?? ''}',
        source: 'HttpService',
      );

      if (messageDetail?.contains('(60)') ?? false) {
        return ApiResponse(
          isSuccessful: true,
          message: message,
          messageDetail: messageDetail,
          content: fromJson(json),
        );
      }

      // Verificar si el código 2 es un error de versión (no de token)
      final isVersionError = code == 2 && 
          (messageDetail?.contains('versión') ?? false);
      
      final error = ApiError(code: code, message: messageDetail ?? '');
      if (!isVersionError && (error.isAuthError || code == ApiErrorCode.invalidToken)) {
        await _handleSessionExpired(
          suppressAuthHandling: suppressAuthHandling,
          messageDetail: messageDetail,
        );
        return ApiResponse.error(
            messageDetail: messageDetail ?? '', content: null);
      }

      if (code > 1) {
        return ApiResponse.error(messageDetail: messageDetail ?? '');
      }

      return ApiResponse(
        isSuccessful: true,
        message: message,
        messageDetail: messageDetail,
        content: fromJson(json),
      );
    } catch (e) {
      AppLogger.error('Error en POST request', error: e, source: 'HttpService');
      final error = ApiError(
        code: e is TimeoutException
            ? ApiErrorCode.timeout
            : ApiErrorCode.networkError,
        message: e.toString(),
      );
      return ApiResponse.error(messageDetail: error.userMessage);
    }
  }

  /// PUT
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
      if (!suppressAuthHandling && onTokenRefreshNeeded != null) {
        await onTokenRefreshNeeded!.call();
      }

      final client = http.Client();
      final response = await client
          .put(
        Uri.parse(baseUrl + path),
        headers: _headers,
        body: jsonEncode(data),
      )
          .timeout(const Duration(seconds: 30));

      developer.log('Response Status: ${response.statusCode}',
          name: 'HttpService');
      developer.log('Response Body: ${response.body}', name: 'HttpService');

      if (response.statusCode == 503 || response.statusCode == 501) {
        return ApiResponse.error(
          messageDetail: 'Ocurrió un error en el servidor',
          content: null,
        );
      }

      if (response.statusCode == 401) {
        String? refreshedMessageDetail;
        try {
          final Map<String, dynamic> parsed401 = response.body.isNotEmpty
              ? (jsonDecode(response.body) as Map<String, dynamic>)
              : <String, dynamic>{};
          refreshedMessageDetail = parsed401['messageDetail'] as String?;
        } catch (_) {}

        await _handleSessionExpired(
          suppressAuthHandling: suppressAuthHandling,
          messageDetail: refreshedMessageDetail,
        );

        return ApiResponse.error(
          messageDetail: refreshedMessageDetail ?? 'Su sesión ha finalizado, por favor ingrese de nuevo',
          content: null,
        );
      }

      Map<String, dynamic> json;
      try {
        json = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return ApiResponse.error(messageDetail: null, content: null);
      }

      final int code = json['code'] as int? ?? ApiErrorCode.unknown;
      final String? message = json['message'] as String?;
      final String? messageDetail = json['messageDetail'] as String?;

      AppLogger.log(
        'Parsed PUT response -> code: $code, message: ${message ?? ''}, messageDetail: ${messageDetail ?? ''}',
        source: 'HttpService',
      );

      if (code > 1) {
        final error = ApiError(code: code, message: messageDetail ?? '');
        developer.log(
          'API Error:\n- Code: $code\n- Detail: $messageDetail',
          name: 'HttpService',
          error: error,
        );
        return ApiResponse.error(messageDetail: error.userMessage);
      }

      return ApiResponse(
        isSuccessful: true,
        message: message,
        messageDetail: messageDetail,
        content: fromJson != null ? fromJson(json) : null,
      );
    } catch (e) {
      AppLogger.error('Error en PUT request', error: e, source: 'HttpService');
      final error = ApiError(
        code: e is TimeoutException
            ? ApiErrorCode.timeout
            : ApiErrorCode.networkError,
        message: e.toString(),
      );
      return ApiResponse.error(messageDetail: error.userMessage);
    }
  }
}
