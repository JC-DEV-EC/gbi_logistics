import 'package:flutter/foundation.dart';
import '../services/guide_validation_service.dart';
import '../models/validate_guide_models.dart';
import '../../../core/models/api_response.dart';

class GuideValidationProvider extends ChangeNotifier {
  final GuideValidationService _service;
  
  List<ClientBySubcourierItem> _clients = [];
  String? _error;
  bool _isLoading = false;
  
  GuideValidationProvider(this._service);

  List<ClientBySubcourierItem> get clients => _clients;
  String? get error => _error;
  bool get isLoading => _isLoading;

  /// Validar una guía para el proceso de registro en cubo
  Future<ApiResponse<void>> validateGuideForCube({
    required String guideCode,
    int? subcourierId,
    String? clientId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = ValidateGuideStatusByProcessRequest(
        guideCode: guideCode,
        subcourierId: subcourierId,
        clientId: clientId,
        processInformation: ValidateGuideProcessType.toRegisterCube,
      );
      
      final response = await _service.validateGuideStatusByProcess(request);
      
      // Verificar tanto el estado de la respuesta como el contenido del mensaje
      final bool hasError = !response.isSuccessful || 
          response.messageDetail?.toLowerCase().contains('error') == true ||
          response.messageDetail?.toLowerCase().contains('estado') == true ||
          response.messageDetail?.toLowerCase().contains('no corresponde') == true;

      if (hasError) {
        return ApiResponse(
          isSuccessful: false,
          messageDetail: response.messageDetail,
        );
      }
      
      return response;
    } catch (e) {
      _error = e.toString();
      return ApiResponse(
        isSuccessful: false,
        messageDetail: _error,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar clientes para un subcourier
  Future<void> loadClients() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _service.getClientsBySubcourier();
      
      if (response.isSuccessful && response.content != null) {
        _clients = response.content!.clients ?? [];
      } else {
        _error = response.messageDetail;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Limpiar clientes
  void clearClients() {
    _clients = [];
    notifyListeners();
  }
}