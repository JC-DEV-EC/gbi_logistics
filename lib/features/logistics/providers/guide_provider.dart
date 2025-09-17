import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/models/api_response.dart';
import '../services/guide_service.dart';
import '../models/operation_models.dart';

/// Provider para manejar operaciones con guías y sus estados
class GuideProvider extends ChangeNotifier {
  final GuideService _guideService;

  // Claves para persistencia
  static const String _validatedGuidesKey = 'validated_guides';
  static const String _dispatchedGuidesKey = 'dispatched_guides';

  // Estado interno
  bool _isLoading = false;
  String? _error;
  List<GuideInfo> _guides = [];
  int _totalGuides = 0;
  final Map<String, String> _guideUiStates = {};
  int? _selectedSubcourierId;
  final Set<String> _selectedGuides = {};

  // Constructor
  GuideProvider(this._guideService) {
    _loadSavedStates();
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<GuideInfo> get guides => _guides;
  int get totalGuides => _totalGuides;
  Map<String, String> get guideUiStates => _guideUiStates;
  int? get selectedSubcourierId => _selectedSubcourierId;
  Set<String> get selectedGuides => Set.unmodifiable(_selectedGuides);

  // Métodos de subcourier
  void setSelectedSubcourier(int id) {
    _selectedSubcourierId = id;
    notifyListeners();
  }

  // Métodos de persistencia
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
        source: 'GuideProvider'
      );

      notifyListeners();
    } catch (e) {
      AppLogger.error('Error cargando estados', error: e, source: 'GuideProvider');
    }
  }

  Future<void> _saveStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final validatedGuides = _guideUiStates.entries
          .where((e) => e.value == 'validated')
          .map((e) => e.key)
          .toList();

      final dispatchedGuides = _guideUiStates.entries
          .where((e) => e.value == 'dispatched')
          .map((e) => e.key)
          .toList();

      await prefs.setStringList(_validatedGuidesKey, validatedGuides);
      await prefs.setStringList(_dispatchedGuidesKey, dispatchedGuides);

      AppLogger.log(
        'Estados guardados: ${validatedGuides.length} validadas, ${dispatchedGuides.length} despachadas',
        source: 'GuideProvider'
      );
    } catch (e) {
      AppLogger.error('Error guardando estados', error: e, source: 'GuideProvider');
    }
  }

  // Métodos de búsqueda y carga
  Future<void> loadGuides({
    required int page,
    required int pageSize,
    required String status,
    String? guideCode,
    bool hideValidated = false,
  }) async {
    try {
      if (_isLoading) {
        AppLogger.log('Omitiendo carga: ya hay una en proceso', source: 'GuideProvider');
        return;
      }
      
      _isLoading = true;
      _error = null;
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
          _guides = _guides
              .where((guide) => 
                !_guideUiStates.containsKey(guide.code) || 
                (_guideUiStates[guide.code] != 'validated' && 
                 _guideUiStates[guide.code] != 'dispatched'))
              .toList();
        }

        _totalGuides = response.content!.totalRegister;
        _error = null;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Busca guías según parámetros sin actualizar estado
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

  /// Busca una guía por código exacto, filtrando por estado en el servidor.
  /// Nota: el backend devuelve solo 'stateLabel' (etiqueta) en los listados,
  /// por lo que NO debemos comparar contra el código de estado (en inglés).
  /// Además, la búsqueda es paginada; si hay más resultados que el tamaño
  /// de página, iteramos páginas hasta encontrar coincidencia (con límite).
  Future<GuideInfo?> searchGuide(String code, {required String status}) async {
    try {
      AppLogger.log(
        'Buscando guía $code con estado $status',
        source: 'GuideProvider'
      );

      const pageSize = 50; // buscar en bloques de 50
      int page = 1;
      int fetched = 0;
      int total = 0;
      const int maxPages = 5; // seguridad para no abusar del backend

      while (page <= maxPages) {
        final resp = await _guideService.getGuidesPaginated(
          page: page,
          pageSize: pageSize,
          status: status,
          guideCode: code,
        );

        if (!resp.isSuccessful || resp.content == null) {
          if (resp.message?.contains('(61)') ?? false) {
            _error = 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.';
            _guides.clear();
            _guideUiStates.clear();
            _selectedGuides.clear();
          }
          return null;
        }

        total = resp.content!.totalRegister;
        fetched += resp.content!.registers.length;

        // Buscar coincidencia exacta solo por código, el estado ya lo filtró el backend
        final match = resp.content!.registers
            .where((g) => (g.code ?? '').toLowerCase() == code.toLowerCase())
            .firstOrNull;
        if (match != null) {
          AppLogger.log(
            'Guía $code encontrada (stateLabel=${match.stateLabel}) en página $page de ${((total + pageSize - 1) / pageSize).ceil()}',
            source: 'GuideProvider'
          );
          return match;
        }

        // Si ya cubrimos todos los resultados potenciales, salir
        if (fetched >= total || resp.content!.registers.isEmpty) {
          break;
        }
        page += 1;
      }

      AppLogger.log(
        'Guía $code no encontrada con estado filtrado $status (total=$total, revisadas=$fetched)',
        source: 'GuideProvider'
      );
      return null;

    } catch (e) {
      AppLogger.error('Error buscando guía', error: e, source: 'GuideProvider');
      return null;
    }
  }

  // Métodos de despacho
  Future<ApiResponse<void>> dispatchToClient(DispatchGuideToClientRequest request) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Llamar directamente al endpoint dispatch-to-client
      final response = await _guideService.dispatchToClient(request);

      if (!response.isSuccessful) {
        if (response.message?.contains('sesión ha expirado') ?? false) {
          _guides.clear();
          _guideUiStates.clear();
          _selectedGuides.clear();
        }
        _error = response.message;
      }

      return response;
    } catch (e) {
      _error = e.toString();
      return ApiResponse<UpdateGuideStatusResponse>.error(message: e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Métodos de estado UI
  Future<void> updateGuideUiState(String guideCode, String state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final validatedGuides = Set<String>.from(prefs.getStringList(_validatedGuidesKey) ?? []);
      final dispatchedGuides = Set<String>.from(prefs.getStringList(_dispatchedGuidesKey) ?? []);

      _guideUiStates[guideCode] = state;

      if (state == 'validated') {
        validatedGuides.add(guideCode);
        dispatchedGuides.remove(guideCode);
      } else if (state == 'dispatched') {
        dispatchedGuides.add(guideCode);
        validatedGuides.remove(guideCode);
      }

      await prefs.setStringList(_validatedGuidesKey, validatedGuides.toList());
      await prefs.setStringList(_dispatchedGuidesKey, dispatchedGuides.toList());

      AppLogger.log(
        'Estado actualizado para guía $guideCode: $state\n' 
        'Estados: ${validatedGuides.length} validadas, ${dispatchedGuides.length} despachadas',
        source: 'GuideProvider'
      );

      notifyListeners();
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

  // Métodos de selección
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

  // Métodos de gestión de errores
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Métodos de gestión directa de guías
  void setGuides(List<GuideInfo> guides) {
    _guides = guides;
    notifyListeners();
  }

  /// Actualiza el estado de una guía en el backend
  Future<ApiResponse<void>> updateGuideStatus(UpdateGuideStatusRequest request) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _guideService.updateGuideStatus(request);
      
      if (!response.isSuccessful) {
        _error = response.message;
      }

      return response;
    } catch (e) {
      _error = e.toString();
      return ApiResponse.error(message: e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
