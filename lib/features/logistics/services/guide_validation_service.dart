import '../../../core/services/http_service.dart';
import '../../../core/config/api_config.dart';
import '../../../core/models/api_response.dart';
import '../models/validate_guide_models.dart';

/// Servicio para validación de guías y obtención de clientes
class GuideValidationService {
  final HttpService _http;

  GuideValidationService(this._http);

  /// Validar estado de guía por proceso
  Future<ApiResponse<void>> validateGuideStatusByProcess(
    ValidateGuideStatusByProcessRequest request,
  ) async {
    return _http.post<void>(
      '${ApiEndpoints.validateGuideStatusByProcess}?version=${ApiConfig.version}',
      request.toJson(),
      (_) {},
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