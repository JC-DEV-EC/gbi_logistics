import 'package:flutter/foundation.dart';

/// Códigos de error de la API
class ApiErrorCode {
  // Errores de autenticación (1-99)
  static const int SESSION_EXPIRED = 60;
  static const int INVALID_TOKEN = 61;
  static const int INVALID_CREDENTIALS = 62;

  // Errores de validación (100-199)
  static const int INVALID_INPUT = 100;
  static const int INVALID_STATE = 101;
  static const int DUPLICATE_ENTRY = 102;

  // Errores de negocio (200-299)
  static const int GUIDE_NOT_FOUND = 200;
  static const int INVALID_GUIDE_STATE = 201;
  static const int CUBE_NOT_FOUND = 202;
  static const int INVALID_CUBE_STATE = 203;
  static const int INVALID_OPERATION = 204;

  // Errores de red (400-499)
  static const int NETWORK_ERROR = 400;
  static const int TIMEOUT = 408;
  static const int UNKNOWN = 499;

  // Errores de servidor (500+)
  static const int SERVER_ERROR = 500;
  static const int SERVICE_UNAVAILABLE = 503;
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
      code: ApiErrorCode.SERVER_ERROR,
      message: message ?? 'Error interno del servidor',
    );
  }

  /// Crea un error para errores de conexión
  factory ApiError.networkError([String? message]) {
    return ApiError(
      code: ApiErrorCode.SERVICE_UNAVAILABLE,
      message: message ?? 'Error de conexión',
    );
  }

  /// Crea un error para sesión expirada
  factory ApiError.sessionExpired([String? message]) {
    return ApiError(
      code: ApiErrorCode.SESSION_EXPIRED,
      message: message ?? 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.',
    );
  }

  /// Indica si el error es de autenticación
  bool get isAuthError => code >= 60 && code < 100;

  /// Indica si el error es de validación
  bool get isValidationError => code >= 100 && code < 200;

  /// Indica si el error es de negocio
  bool get isBusinessError => code >= 200 && code < 500;

  /// Indica si el error es de servidor
  bool get isServerError => code >= 500;

  /// Obtiene un mensaje amigable para mostrar al usuario
  String get userMessage {
    switch (code) {
      case ApiErrorCode.SESSION_EXPIRED:
      case ApiErrorCode.INVALID_TOKEN:
        return 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.';

      case ApiErrorCode.INVALID_CREDENTIALS:
        return 'Credenciales inválidas. Por favor, verifica tus datos.';

      case ApiErrorCode.INVALID_INPUT:
        return 'Datos inválidos. Por favor, verifica la información ingresada.';

      case ApiErrorCode.INVALID_STATE:
        return 'Estado inválido para esta operación.';

      case ApiErrorCode.DUPLICATE_ENTRY:
        return 'Ya existe un registro con estos datos.';

      case ApiErrorCode.GUIDE_NOT_FOUND:
        return 'Guía no encontrada.';

      case ApiErrorCode.INVALID_GUIDE_STATE:
        return 'Estado inválido de la guía para esta operación.';

      case ApiErrorCode.CUBE_NOT_FOUND:
        return 'Cubo no encontrado.';

      case ApiErrorCode.INVALID_CUBE_STATE:
        return 'Estado inválido del cubo para esta operación.';

      case ApiErrorCode.INVALID_OPERATION:
        return 'Operación inválida en este momento.';

      case ApiErrorCode.SERVER_ERROR:
        return 'Error interno del servidor. Por favor, intenta más tarde.';

      case ApiErrorCode.SERVICE_UNAVAILABLE:
        return 'Servicio no disponible. Por favor, intenta más tarde.';

      case ApiErrorCode.NETWORK_ERROR:
        return 'Error de conexión. Verifica tu conexión a internet.';

      case ApiErrorCode.TIMEOUT:
        return 'La solicitud ha tardado demasiado tiempo. Por favor, intenta nuevamente.';

      case ApiErrorCode.UNKNOWN:
        return 'Ha ocurrido un error inesperado. Por favor, intenta nuevamente.';

      default:
        return message;
    }
  }

  /// Indica si el error puede resolverse reintentando la operación
  bool get isRetryable {
    return isServerError || code == ApiErrorCode.SERVICE_UNAVAILABLE;
  }

  /// Indica si el error requiere cerrar sesión
  bool get requiresLogout {
    return code == ApiErrorCode.SESSION_EXPIRED || code == ApiErrorCode.INVALID_TOKEN;
  }

  @override
  String toString() => 'ApiError($code): $message${details != null ? ' - $details' : ''}';
}
