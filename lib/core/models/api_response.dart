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
      message: message,
      messageDetail: messageDetail,
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
      message: message,
      messageDetail: messageDetail,
      content: content,
    );
  }
}