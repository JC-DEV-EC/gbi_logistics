import '../../../core/services/http_service.dart';
import '../../../core/config/api_config.dart';
import '../../../core/models/api_response.dart';
import '../models/validate_guide_models.dart';

/// Servicio para validación de guías y obtención de clientes
class GuideValidationService {
  final HttpService _http;

  GuideValidationService(this._http);

  /// Validar estado de guía por proceso
  Future<ApiResponse<ValidateGuideStatusResponse>> validateGuideStatusByProcess(
    ValidateGuideStatusByProcessRequest request,
  ) async {
    return _http.post<ValidateGuideStatusResponse>(
      '${ApiEndpoints.validateGuideStatusByProcess}?version=${ApiConfig.version}',
      request.toJson(),
      (json) {
        // Debug: Imprimir el JSON completo
        print('[DEBUG-JSON] Complete response: $json');
        
        // Obtener el código general de la respuesta
        final code = json['code'] as int? ?? -1;
        final isSuccess = code == 0;
        
        // Si hay content, intentar parsearlo, pero usar el código general como fallback
        if (json['content'] != null) {
          print('[DEBUG-JSON] Content exists: ${json['content']}');
          final contentMap = json['content'] as Map<String, dynamic>;
          
          // Si el content tiene isValid, usarlo. Si no, usar el código general
          final contentHasIsValid = contentMap.containsKey('isValid');
          
          return ValidateGuideStatusResponse(
            isValid: contentHasIsValid ? (contentMap['isValid'] as bool? ?? false) : isSuccess,
            currentState: contentMap['currentState'] as String?,
            requiredState: contentMap['requiredState'] as String?,
            message: contentMap['message'] as String?,
            userMessage: contentMap['userMessage'] as String?,
          );
        } else {
          // Sin content, usar el código general
          print('[DEBUG-JSON] No content, code: $code, creating response with isValid: $isSuccess');
          return ValidateGuideStatusResponse(
            isValid: isSuccess,
            message: json['message'] as String?,
          );
        }
      },
    );
  }

  /// Obtener clientes por subcourier
  Future<ApiResponse<GetClientBySubcourierResponse>> getClientsBySubcourier(int subcourierId) async {
    return _http.get<GetClientBySubcourierResponse>(
      '${ApiEndpoints.getClientBySubcourier}?version=${ApiConfig.version}&subcourierId=$subcourierId',
      (json) => GetClientBySubcourierResponse.fromJson(json['content'] as Map<String, dynamic>),
    );
  }
}