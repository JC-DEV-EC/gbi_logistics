import 'package:flutter/foundation.dart';

/// Códigos de error de la API
class ApiErrorCode {
  // Errores de autenticación (1-99)
  static const int sessionExpired = 1;
  static const int invalidToken = 2;
  static const int invalidCredentials = 3;
  
  // Errores de estados (60-69)
  static const int invalidStateForOperation = 60;

  // Errores de validación (100-199)
  static const int invalidInput = 100;
  static const int invalidState = 101;
  static const int duplicateEntry = 102;

  // Errores de negocio (200-299)
  static const int guideNotFound = 200;
  static const int invalidGuideState = 201;
  static const int cubeNotFound = 202;
  static const int invalidCubeState = 203;
  static const int invalidOperation = 204;

  // Errores de red (400-499)
  static const int networkError = 400;
  static const int timeout = 408;
  static const int unknown = 499;

  // Errores de servidor (500+)
  static const int serverError = 500;
  static const int serviceUnavailable = 503;
}

/// Modelo para errores de la API
@immutable
class ApiError implements Exception {
  final int code;
  final String message;
  final Map<String, dynamic>? details;

  const ApiError({
    required this.code,
    required this.message,
    this.details,
  });

  /// Crea un error desde un mapa de datos
  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] as int,
      message: json['message'] as String? ?? 'Error desconocido',
      details: json['details'] as Map<String, dynamic>?,
    );
  }

  /// Crea un error para errores de servidor (500)
  factory ApiError.serverError([String? message]) {
    return ApiError(
      code: ApiErrorCode.serverError,
      message: message ?? '',  // Let backend provide the message
    );
  }

  /// Crea un error para errores de conexión
  factory ApiError.networkError([String? message]) {
    return ApiError(
      code: ApiErrorCode.serviceUnavailable,
      message: message ?? '',  // Let backend provide the message
    );
  }

  /// Crea un error para sesión expirada
  factory ApiError.sessionExpired([String? message]) {
    return ApiError(
      code: ApiErrorCode.sessionExpired,
      message: message ?? '',  // Let backend provide the message
    );
  }

  /// Indica si el error es de autenticación
  bool get isAuthError => code >= 1 && code < 10;

  /// Indica si el error es de validación
  bool get isValidationError => code >= 100 && code < 200;

  /// Indica si el error es de negocio
  bool get isBusinessError => code >= 200 && code < 500;

  /// Indica si el error es de servidor
  bool get isServerError => code >= 500;

  /// Obtiene un mensaje amigable para mostrar al usuario
  String get userMessage => message;  // Always use the message from backend

  /// Indica si el error puede resolverse reintentando la operación
  bool get isRetryable {
    return isServerError || code == ApiErrorCode.serviceUnavailable;
  }

  /// Indica si el error requiere cerrar sesión
  bool get requiresLogout {
    return code == ApiErrorCode.sessionExpired || code == ApiErrorCode.invalidToken;
  }

  @override
  String toString() => 'ApiError($code): $message${details != null ? ' - $details' : ''}';
}
