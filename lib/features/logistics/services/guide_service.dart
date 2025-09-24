import '../../../core/services/http_service.dart';
import '../../../core/config/api_config.dart';
import '../../../core/models/api_response.dart';
import '../../../core/services/app_logger.dart';
import '../models/operation_models.dart';

/// Servicio para gestión de guías
class GuideService {
  final HttpService _http;

  GuideService(this._http);

  /// Obtiene las guías paginadas
  Future<ApiResponse<GetGuidesPaginatedResponse>> getGuidesPaginated({
    required int page,
    required int pageSize,
    required String status,
    String? guideCode,
  }) async {
    return _http.get<GetGuidesPaginatedResponse>(
      ApiEndpoints.guidesPaginated,
      (json) => GetGuidesPaginatedResponse.fromJson(json),
      queryParams: {
        'Page': page,
        'ItemsByPage': pageSize,
        'Status': status,  // API espera 'Status' para guías (ya viene codificado si es necesario)
        if (guideCode != null) 'GuideCode': guideCode,
      },
    );
  }

  /// Actualiza el estado de una guía
  /// Actualiza el estado de una o más guías
  Future<ApiResponse<void>> updateGuideStatus(UpdateGuideStatusRequest request, {
    bool suppressAuthHandling = true,
  }) async {
    if (request.guides.isEmpty) {
      return ApiResponse.error(message: 'No hay guías para actualizar');
    }

    AppLogger.log(
      'Actualizando estado de ${request.guides.length} guías a ${request.newStatus}',
      source: 'GuideService'
    );

    final response = await _http.post<void>(
      ApiEndpoints.updateGuideStatus,
      request.toJson(),
      (_) => null,
      suppressAuthHandling: true,
    );

    AppLogger.log(
      'Resultado de actualización:\n'
      '- Exitoso: ${response.isSuccessful}\n'
      '- Mensaje: ${response.messageDetail ?? response.message}',
      source: 'GuideService'
    );

    return response;
  }

  /// Despacha una guía a cliente
  Future<ApiResponse<void>> dispatchToClient(DispatchGuideToClientRequest request) async {
    AppLogger.log(
      'Despachando guías a cliente:\nSubcourier: ${request.subcourierId}\nGuías: ${request.guides.join(", ")}',
      source: 'GuideService'
    );

    AppLogger.log(
      'Request de despacho:\n'
      'URL: ${ApiEndpoints.dispatchToClient}\n'
      'Body: ${request.toJson()}',
      source: 'GuideService'
    );

    final response = await _http.post<void>(
      ApiEndpoints.dispatchToClient,
      request.toJson(),
      (json) {
        AppLogger.log(
          'Respuesta raw del backend:\n${json.toString()}',
          source: 'GuideService'
        );
        // No necesitamos parsear el content, solo usar el code/message/messageDetail
        return null;
      },
    );

    AppLogger.log(
      'Respuesta despacho:\nExitoso: ${response.isSuccessful}\nMensaje: ${response.messageDetail ?? response.message}',
      source: 'GuideService'
    );

    return response;
  }
}
