import 'dart:developer' as developer;
import '../../../core/services/http_service.dart';
import '../../../core/config/api_config.dart';
import '../../../core/models/api_response.dart';
import '../models/operation_models.dart';
import '../models/transport_cube_details.dart';
import '../models/transport_cube_scan.dart';
import '../../../core/services/app_logger.dart';

/// Servicio para gestión de cubos de transporte
class TransportCubeService {
  final HttpService _http;

  TransportCubeService(this._http);

  /// Crea un nuevo cubo de transporte
  /// @param request Las guías a incluir en el cubo
  Future<ApiResponse<NewTransportCubeResponseGenericResponse>> createTransportCube(NewTransportCubeRequest request) async {
    // Log del request que se envía
    AppLogger.log(
      'POST /api/v1.0/Guide/new-transport-cube\nRequest:\n${request.toJson()}',
      source: 'TransportCubeService'
    );

    final pathWithVersion = '${ApiEndpoints.newTransportCube}?version=${ApiConfig.version}';
    final response = await _http.post<NewTransportCubeResponseGenericResponse>(
      pathWithVersion,
      request.toJson(),
      (json) => NewTransportCubeResponseGenericResponse.fromJson(json),
    );

    if (!response.isSuccessful) {
      AppLogger.error(
        'Failed to create transport cube:\n${response.messageDetail ?? response.message}',
        source: 'TransportCubeService'
      );
    } else {
      AppLogger.log(
        'Transport cube created successfully - id: ${response.content?.content?.id}, Label: ${response.content?.content?.transportCubeLabelId}',
        source: 'TransportCubeService',
        type: 'SUCCESS'
      );
      // Si el ID es -1, indicar claramente que el backend no devolvió content válido
      if ((response.content?.content?.id ?? -1) == -1) {
        developer.log(
          'Warning: Backend responded success but without valid content (id/label).',
          name: 'TransportCubeService',
        );
      }
    }

    return response;
  }

  /// Obtiene la lista de cubos de transporte
  Future<ApiResponse<GetTransportCubesPaginatedResponse>> getTransportCubes({
    required int page,
    required int itemsPerPage,
    required String state,
  }) async {
    AppLogger.log(
      'Getting transport cubes with params:\nPage: $page\nItemsPerPage: $itemsPerPage\nState: $state',
      source: 'TransportCubeService'
    );

    return _http.get<GetTransportCubesPaginatedResponse>(
      ApiEndpoints.getTransportCubes,
      (json) => GetTransportCubesPaginatedResponse.fromJson(json),
      queryParams: {
        'version': ApiConfig.version,
        'Page': page.toString(),
        'ItemsByPage': itemsPerPage.toString(),
          'State': state,  // API espera 'State' para cubos de transporte
      },
    );
  }

  /// Obtiene los detalles de un cubo
  Future<ApiResponse<TransportCubeDetails>> getTransportCubeDetails(
    int cubeId, {
    bool suppressAuthHandling = false,
  }) async {
    developer.log('Getting details for cube $cubeId', name: 'TransportCubeService');
    final response = await _http.get<TransportCubeDetails>(
      ApiEndpoints.getTransportCubeDetails,
      (json) {
        developer.log('Response JSON: $json', name: 'TransportCubeService');
        return TransportCubeDetails.fromJson(json);
      },
      queryParams: {
        'version': ApiConfig.version,
        'TransportCubeId': cubeId,
      },
      suppressAuthHandling: suppressAuthHandling,
    );

    if (!response.isSuccessful) {
      developer.log('Failed to get cube details: ${response.messageDetail ?? response.message}', name: 'TransportCubeService');
    }

    return response;
  }

  /// Cambia el estado de uno o más cubos de transporte
  Future<ApiResponse<void>> changeTransportCubesState(
    ChangeTranportCubesStateRequest request,
  ) async {
    developer.log(
      'Sending state change request:\\n- Cube IDs: ${request.transportCubeIds.join(", ")}\\n- New state: ${request.newState}',
      name: 'TransportCubeService',
    );

    final response = await _http.put<void>(
      '${ApiEndpoints.changeTransportCubeState}?version=${ApiConfig.version}',
      request.toJson(),
      (_) => null,
      suppressAuthHandling: true,  // Evitar manejo automático de auth
    );

    if (!response.isSuccessful) {
      developer.log(
        'Failed to change cubes state - Error: ${response.messageDetail ?? response.message}',
        name: 'TransportCubeService',
      );
    } else {
      developer.log(
        'Successfully changed state for ${request.transportCubeIds.length} cube(s)',
        name: 'TransportCubeService',
      );
    }

    return response;
  }

  /// Mueve una guía entre cubos
  Future<ApiResponse<void>> moveGuideBetweenCubes(
    ChangeCubeGuideRequest request,
  ) async {
    return _http.put<void>(
      ApiEndpoints.changeCubeGuide,
      request.toJson(),
      null,
    );
  }

  /// Obtiene el historial de un cubo
  Future<ApiResponse<List<String>>> getCubeHistory(int cubeId) async {
    final response = await _http.get<List<dynamic>>(
'${ApiEndpoints.getTransportCubeDetails}/history',
      (json) => (json as List).cast<String>(),
      queryParams: {'cubeId': cubeId},
    );

    return ApiResponse(
      isSuccessful: response.isSuccessful,
      messageDetail	: response.messageDetail,
      content: response.content?.cast<String>(),
    );
  }


  Future<ApiResponse<void>> verifyTransportCubeScan(TransportCubeScanRequest request) async {
    return _http.post<void>(
'${ApiEndpoints.getTransportCubes}/verify-scan',
      request.toJson(),
      (_) => null,
    );
  }
}
