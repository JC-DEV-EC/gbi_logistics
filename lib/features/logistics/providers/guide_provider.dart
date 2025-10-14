import 'package:flutter/foundation.dart';
import 'package:logiruta/core/services/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/api_response.dart';
import '../models/operation_models.dart';
import '../services/guide_service.dart';

/// Provider para manejar operaciones con guías y sus estados.
///
/// Proporciona funcionalidades para:
/// - Cargar y buscar guías por estado
/// - Gestionar estados de UI (validadas/despachadas)
/// - Mantener selección de guías y subcourier
/// - Gestionar el filtro de estado en Despacho a Cliente
class GuideProvider extends ChangeNotifier {
  final GuideService _guideService;

  // Claves para persistencia
  static const String _validatedGuidesKey = 'validated_guides';
  static const String _dispatchedGuidesKey = 'dispatched_guides';

  // Estado interno
  bool _isLoading = false;
  final ValueNotifier<String?> _errorNotifier = ValueNotifier<String?>(null);
  bool _lastOperationSuccessful = false;
  List<GuideInfo> _guides = [];
  int _totalGuides = 0;
  final Map<String, String> _guideUiStates = {};
  int? _selectedSubcourierId;
  String? _selectedClientId;
  bool _requiresClient = false;
  bool _selectorsLocked = false;
  final Set<String> _selectedGuides = {};

  // Estado actual del filtro en Despacho a Cliente
  String _clientDispatchFilterState = 'ReceivedInLocalWarehouse';

  // Constructor
  GuideProvider(this._guideService) {
    _loadSavedStates();
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _errorNotifier.value;
  ValueNotifier<String?> get errorNotifier => _errorNotifier;
  bool get lastOperationSuccessful => _lastOperationSuccessful;
  List<GuideInfo> get guides => _guides;
  int get totalGuides => _totalGuides;
  Map<String, String> get guideUiStates => _guideUiStates;
  int? get selectedSubcourierId => _selectedSubcourierId;
  String? get selectedClientId => _selectedClientId;
  bool get requiresClient => _requiresClient;
  bool get selectorsLocked => _selectorsLocked;
  Set<String> get selectedGuides => Set.unmodifiable(_selectedGuides);
  String get clientDispatchFilterState => _clientDispatchFilterState;

  // Métodos de subcourier y cliente
  void setSelectedSubcourier(int id) {
    if (_selectorsLocked) return;
    _selectedSubcourierId = id;
    notifyListeners();
  }

  void setSelectedClient(String? id) {
    if (_selectorsLocked) return;
    _selectedClientId = id;
    notifyListeners();
  }

  void setRequiresClient(bool requires) {
    _requiresClient = requires;
    if (!requires) {
      _selectedClientId = null;
    }
    notifyListeners();
  }

  void lockSelectors() {
    _selectorsLocked = true;
    notifyListeners();
  }

  void unlockSelectors() {
    _selectorsLocked = false;
    notifyListeners();
  }

  bool get canStartScanning {
    final hasSubcourier = _selectedSubcourierId != null;
    final hasClient = !_requiresClient || _selectedClientId != null;
    return hasSubcourier && hasClient;
  }

  void resetSelections() {
    _selectedSubcourierId = null;
    _selectedClientId = null;
    _requiresClient = false;
    notifyListeners();
  }

  // -----------------------------
  // Métodos de persistencia
  // -----------------------------
  Future<void> _loadSavedStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final validatedGuides = prefs.getStringList(_validatedGuidesKey) ?? [];
      final dispatchedGuides = prefs.getStringList(_dispatchedGuidesKey) ?? [];

      _guideUiStates.clear();

      for (final guide in validatedGuides) {
        _guideUiStates[guide] = 'validated';
      }
      for (final guide in dispatchedGuides) {
        _guideUiStates[guide] = 'dispatched';
      }

      AppLogger.log(
        'Estados cargados:\n'
            '- Validadas (${validatedGuides.length}): ${validatedGuides.join(", ")}\n'
            '- Despachadas (${dispatchedGuides.length}): ${dispatchedGuides.join(", ")}',
        source: 'GuideProvider',
      );

      notifyListeners();
    } catch (e) {
      AppLogger.error('Error cargando estados', error: e, source: 'GuideProvider');
    }
  }

  // -----------------------------
  // Métodos de búsqueda y carga
  // -----------------------------
  Future<void> loadGuides({
    required int page,
    required int pageSize,
    required String status,
    String? guideCode,
    bool hideValidated = false,
    bool bypassLoadingGuard = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.log('[PERFORMANCE] Iniciando loadGuides', source: 'GuideProvider');
    
    try {

      if (_isLoading && !bypassLoadingGuard) {
        AppLogger.log('Omitiendo carga: ya hay una en proceso', source: 'GuideProvider');
        return;
      }

      _isLoading = true;
      _errorNotifier.value = null;
      _lastOperationSuccessful = false;
      notifyListeners();

      final response = await _guideService.getGuidesPaginated(
        page: page,
        pageSize: pageSize,
        status: status,
        guideCode: guideCode,
      );

      if (response.isSuccessful && response.content != null) {
        _guides = response.content!.registers;

        if (hideValidated) {
          _guides = _guides.where((guide) {
            final state = _guideUiStates[guide.code];
            return state != 'validated' && state != 'dispatched';
          }).toList();
        }

        // Ordenar para priorizar DispatchedFromCustomsWithOutCube
        _guides.sort((a, b) {
          if (a.stateLabel == 'DispatchedFromCustomsWithOutCube' &&
              b.stateLabel != 'DispatchedFromCustomsWithOutCube') {
            return -1;
          } else if (a.stateLabel != 'DispatchedFromCustomsWithOutCube' &&
              b.stateLabel == 'DispatchedFromCustomsWithOutCube') {
            return 1;
          }
          return 0;
        });

        _totalGuides = response.content!.totalRegister;
      } else {
      _errorNotifier.value = response.messageDetail;
      }
    } catch (e) {
      _errorNotifier.value = e.toString();
    } finally {
      _isLoading = false;
      final totalGuides = _guides.length;
      notifyListeners();
      AppLogger.log('[PERFORMANCE] loadGuides completado en ${stopwatch.elapsedMilliseconds}ms. Guías cargadas: $totalGuides', source: 'GuideProvider');
    }
  }

  Future<List<GuideInfo>> searchGuides({
    required int page,
    required int pageSize,
    required String status,
    String? guideCode,
  }) async {
    try {
      final resp = await _guideService.getGuidesPaginated(
        page: page,
        pageSize: pageSize,
        status: status,
        guideCode: guideCode,
      );

      if (resp.isSuccessful && resp.content != null) {
        return resp.content!.registers;
      }
      return [];
    } catch (e) {
      AppLogger.error('Error buscando guías', error: e, source: 'GuideProvider');
      return [];
    }
  }

  Future<ApiResponse<GuideInfo>> searchGuide(
      String code, {
        required String status,
      }) async {
    try {
      AppLogger.log(
        'Buscando guía $code con estado $status',
        source: 'GuideProvider',
      );

      // Consultar al backend filtrando por estado y código exacto
      final resp = await _guideService.getGuidesPaginated(
        page: 1,
        pageSize: 50,
        status: status,
        guideCode: code,
      );

      AppLogger.log(
        'Response for guide $code:\n- Success: ${resp.isSuccessful}\n- MessageDetail: ${resp.messageDetail}\n- Has content: ${resp.content != null}',
        source: 'GuideProvider'
      );

      // Si la respuesta no es exitosa o no hay contenido, devolver el messageDetail del backend
      if (!resp.isSuccessful || resp.content == null) {
        return ApiResponse.error(messageDetail: resp.messageDetail);
      }

      // Si no hay registros, usar el messageDetail del backend
      if (resp.content!.registers.isEmpty) {
        return ApiResponse.error(messageDetail: resp.messageDetail);
      }

      // Buscar coincidencia exacta por código (ignorando mayúsculas/minúsculas)
      final match = resp.content!.registers
          .where((g) => (g.code ?? '').toLowerCase() == code.toLowerCase())
          .firstOrNull;

      if (match == null) {
        return ApiResponse.error(messageDetail: resp.messageDetail);
      }

      // Retornar la guía encontrada con el message del backend para éxito
      return ApiResponse.success(
        message: resp.message,
        content: match,
      );
    } catch (e) {
      AppLogger.error('Error buscando guía', error: e, source: 'GuideProvider');
      return ApiResponse.error(
        messageDetail: null, // Dejar que el backend proporcione el mensaje en la siguiente interacción
      );
    }
  }

  // -----------------------------
  // Métodos de despacho
  // -----------------------------
  Future<ApiResponse<void>> dispatchToClient(
      DispatchGuideToClientRequest request,
      ) async {
    try {
      _isLoading = true;
      _errorNotifier.value = null;
      _lastOperationSuccessful = false;
      notifyListeners();

      final stopwatch = Stopwatch()..start();
      AppLogger.log('[PERFORMANCE] Iniciando llamada a API dispatchToClient', source: 'GuideProvider');
      final response = await _guideService.dispatchToClient(request);
      AppLogger.log('[PERFORMANCE] API dispatchToClient completada en ${stopwatch.elapsedMilliseconds}ms', source: 'GuideProvider');

      if (response.isSuccessful) {
        _lastOperationSuccessful = true;
        
        // Remover las guías procesadas de la lista y limpiar sus estados
        final processedGuides = request.guides.toSet();
        _guides.removeWhere((guide) => processedGuides.contains(guide.code));
        for (final guide in request.guides) {
          _guideUiStates.remove(guide);
          _selectedGuides.remove(guide);
        }
        
        // NO limpiar selección de subcourier aquí para evitar problemas de contexto
        // Se limpiará en ClientDispatchScanBox después de mostrar el mensaje
      } else if (response.messageDetail?.contains('sesión ha expirado') ?? false) {
        _guides.clear();
        _guideUiStates.clear();
        _selectedGuides.clear();
        _errorNotifier.value = response.messageDetail;
      }

      return response;
    } catch (e) {
      _errorNotifier.value = e.toString();
      return ApiResponse.error(
        messageDetail: _errorNotifier.value,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // -----------------------------
  // Métodos de estado UI
  // -----------------------------
  Future<void> updateGuideUiState(String guideCode, String state) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.log('[PERFORMANCE] Iniciando updateGuideUiState para guía $guideCode', source: 'GuideProvider');
    try {
      final prefs = await SharedPreferences.getInstance();
      final validatedGuides = Set<String>.from(
        prefs.getStringList(_validatedGuidesKey) ?? [],
      );
      final dispatchedGuides = Set<String>.from(
        prefs.getStringList(_dispatchedGuidesKey) ?? [],
      );

      _guideUiStates[guideCode] = state;

      if (state == 'validated') {
        validatedGuides.add(guideCode);
        dispatchedGuides.remove(guideCode);
      } else if (state == 'dispatched') {
        dispatchedGuides.add(guideCode);
        validatedGuides.remove(guideCode);
      }

      await prefs.setStringList(
        _validatedGuidesKey,
        validatedGuides.toList(),
      );
      await prefs.setStringList(
        _dispatchedGuidesKey,
        dispatchedGuides.toList(),
      );

      AppLogger.log(
        'Estado actualizado para guía $guideCode: $state\n'
            'Estados: ${validatedGuides.length} validadas, ${dispatchedGuides.length} despachadas',
        source: 'GuideProvider',
      );

      notifyListeners();
      AppLogger.log('[PERFORMANCE] updateGuideUiState completado en ${stopwatch.elapsedMilliseconds}ms', source: 'GuideProvider');
    } catch (e) {
      AppLogger.error('Error actualizando estado', error: e, source: 'GuideProvider');
    }
  }

  String? getGuideUiState(String guideCode) => _guideUiStates[guideCode];

  void removeGuideUiState(String guideCode) {
    _guideUiStates.remove(guideCode);
    notifyListeners();
  }

  void clearGuideUiStates() {
    _guideUiStates.clear();
    notifyListeners();
  }

  // -----------------------------
  // Métodos de selección
  // -----------------------------
  void toggleGuideSelection(String code) {
    if (_selectedGuides.contains(code)) {
      _selectedGuides.remove(code);
    } else {
      _selectedGuides.add(code);
    }
    notifyListeners();
  }

  bool isGuideSelected(String code) => _selectedGuides.contains(code);

  void clearSelectedGuides() {
    if (_selectedGuides.isNotEmpty) {
      _selectedGuides.clear();
      notifyListeners();
    }
  }

  // -----------------------------
  // Métodos auxiliares
  // -----------------------------
  void setClientDispatchFilterState(String state) {
    if (_clientDispatchFilterState != state) {
      _clientDispatchFilterState = state;
      notifyListeners();
    }
  }

  void clearLastOperationStatus() {
    _lastOperationSuccessful = false;
    notifyListeners();
  }

  void clearError() {
    _errorNotifier.value = null;
    notifyListeners();
  }

  void setGuides(List<GuideInfo> guides) {
    _guides = guides;
    notifyListeners();
  }

  Future<ApiResponse<void>> updateGuideStatus(
      UpdateGuideStatusRequest request,
      ) async {
    try {
      _isLoading = true;
      _errorNotifier.value = null;
      _lastOperationSuccessful = false;
      notifyListeners();

      final response = await _guideService.updateGuideStatus(request);

      // Importante: no propagar errores a un canal global aquí.
      // Las pantallas que llaman a esta operación deben manejar sus mensajes localmente
      // para evitar que mensajes de otros flujos (p. ej. Recepción) aparezcan en
      // pantallas no relacionadas (p. ej. Despacho a Cliente).
      if (!response.isSuccessful) {
        AppLogger.log(
          'updateGuideStatus failed: \'${response.messageDetail ?? ''}\'',
          source: 'GuideProvider',
        );
      }

      return response;
    } catch (e) {
      _errorNotifier.value = e.toString();
      return ApiResponse.error(
        messageDetail: _errorNotifier.value,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
