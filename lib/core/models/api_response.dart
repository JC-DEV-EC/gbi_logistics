/// Respuesta genérica de la API
class ApiResponse<T> {
  final bool isSuccessful;
  final String? message;       // Mensaje general
  final String? messageDetail; // Mensaje detallado (prioridad para mostrar al usuario)
  final T? content;

  const ApiResponse({
    required this.isSuccessful,
    this.message,
    this.messageDetail,
    this.content,
  });

  /// Crea una respuesta de error
  factory ApiResponse.error({
    String? message,
    String? messageDetail,
    T? content,
  }) {
    return ApiResponse(
      isSuccessful: false,
      message: null,  // No usar message para errores, solo messageDetail
      messageDetail: messageDetail ?? message,  // Si no hay messageDetail, usar message como fallback
      content: content,
    );
  }

  /// Crea una respuesta exitosa
  factory ApiResponse.success({
    String? message,
    String? messageDetail,
    T? content,
  }) {
    return ApiResponse(
      isSuccessful: true,
      message: null,  // No usar message para mensajes de éxito
      messageDetail: messageDetail ?? message,  // Si no hay messageDetail, usar message como fallback
      content: content,
    );
  }
}