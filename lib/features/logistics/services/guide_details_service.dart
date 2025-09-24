import '../../../core/services/http_service.dart';
import '../models/guide_details.dart';
import '../../../core/models/api_response.dart';

class GuideDetailsService {
  final HttpService _httpService;

  GuideDetailsService(this._httpService);

  /// Obtiene los detalles de una guía específica
  Future<ApiResponse<GuideDetails>> getGuideDetails(String guideCode) async {
    if (guideCode.isEmpty) {
      return ApiResponse.error(
        messageDetail: 'El código de guía es requerido'
      );
    }

    try {
      final response = await _httpService.get<GuideDetails>(
        '/api/v1/Guide/guide-details',
        (json) => GuideDetails.fromJson(json['content'] as Map<String, dynamic>),
        queryParams: {'guideCode': guideCode},
        suppressAuthHandling: true,  // Evitar manejo automático de autenticación
      );

      // Si la respuesta tiene un mensaje pero no tiene contenido, es un error
      if (!response.isSuccessful || response.content == null) {
        return ApiResponse.error(
          message: response.message,
          messageDetail: response.messageDetail,
        );
      }
      
      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Error al buscar la guía',
        messageDetail: 'Ocurrió un error al buscar la guía: $e',
      );
    }
  }
}