/// Respuesta genérica de la API
class ApiResponse<T> {
  final bool isSuccessful;
  final String? message;        // Mensaje de éxito
  final String? messageDetail; // Mensaje de error detallado
  final T? content;

  const ApiResponse({
    required this.isSuccessful,
    this.message,
    this.messageDetail,
    this.content,
  });

  /// Crea una respuesta de error
  factory ApiResponse.error({
    String? messageDetail,
    T? content,
  }) {
    return ApiResponse(
      isSuccessful: false,
      messageDetail: messageDetail,
      content: content,
    );
  }

  /// Crea una respuesta exitosa
  factory ApiResponse.success({
    String? message,
    T? content,
  }) {
    return ApiResponse(
      isSuccessful: true,
      message: message,
      content: content,
    );
  }
  
  /// Obtiene el mensaje apropiado según el tipo de respuesta
  String? get displayMessage => isSuccessful ? message : messageDetail;
}