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
        'Status': status,  // API espera 'Status' para guías
        if (guideCode != null) 'GuideCode': guideCode,
      },
    );
  }

  /// Actualiza el estado de una guía
  Future<ApiResponse<void>> updateGuideStatus(UpdateGuideStatusRequest request, {
    bool suppressAuthHandling = true,  // Siempre suprimir manejo de autenticación
  }) async {
    AppLogger.log(
      'Calling updateGuideStatus endpoint:\n- Guides: ${request.guides}\n- Status: ${request.newStatus}',
      source: 'GuideService'
    );

    // Primero validar que el token siga siendo válido
    final validateResponse = await _http.get<dynamic>(
      ApiEndpoints.dashboardData,
      (json) => json,
      suppressAuthHandling: true,
      queryParams: {'version': '1.0'},
    );

    // Si la validación falló, continuar con la operación normal
    final response = await _http.post<void>(
      ApiEndpoints.updateGuideStatus,
      request.toJson(),
      (_) => null,
      suppressAuthHandling: true, // Siempre suprimir manejo de autenticación
    );

    AppLogger.log(
      'updateGuideStatus response:\n- Success: ${response.isSuccessful}\n- Message: ${response.message}',
      source: 'GuideService'
    );

    return response;
  }

  /// Despacha una guía a cliente
  Future<ApiResponse<void>> dispatchToClient(DispatchGuideToClientRequest request) async {
    return _http.post<void>(
      ApiEndpoints.dispatchToClient,
      request.toJson(),
      (_) => null,
    );
  }
}
