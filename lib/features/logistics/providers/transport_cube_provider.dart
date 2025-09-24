import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'dart:math' show max;
import '../../../core/services/app_logger.dart';
import '../../../core/models/api_response.dart';
import '../services/transport_cube_service.dart';
import '../models/transport_cube_state.dart';
import '../models/transport_cube_details.dart';
import '../models/operation_models.dart' as op;
import '../models/operation_models.dart';

/// Provider para manejo local de cubos de transporte
class TransportCubeProvider extends ChangeNotifier {
  // Estado
  bool _isLoading = false;
  String? _errorMessage;
  String? _lastMessageDetail;
  String _selectedState = TransportCubeState.CREATED; // Estado inicial cuando el cubo se crea en aduana
  final Map<int, bool> _loadingDetails = {}; // Rastrear peticiones de detalles por cubeId
  List<op.TransportCubeInfoAPI> _cubes = [];
  TransportCubeDetails? _selectedCubeDetails;
  final Set<int> _selectedCubes = {};
  final TransportCubeService _service;
  // Cache de futures de detalles por cubo para evitar llamadas duplicadas
  final Map<int, Future<TransportCubeDetails>> _detailsFutures = {};

  // Exponer service para uso interno
  TransportCubeService get service => _service;

  TransportCubeProvider(this._service);

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get error => _errorMessage;
  String? get lastMessageDetail => _lastMessageDetail;
  String get selectedState => _selectedState;
List<op.TransportCubeInfoAPI> get cubes {
    developer.log(
      'Pre-filter cubes state:\n'
      '- Total cubes: ${_cubes.length}\n'
      '- First cube state: ${_cubes.firstOrNull?.state}\n'
      '- Selected state: $_selectedState',
      name: 'TransportCubeProvider'
    );

    final filteredCubes = _cubes.where(
      (cube) => cube.state == _selectedState
    ).toList();

    developer.log(
      'Getting cubes:\n'
      '- Total cubes: ${_cubes.length}\n'
      '- Selected state: $_selectedState\n'
      '- Filtered cubes: ${filteredCubes.length}\n'
      '- Error message: $_errorMessage',
      name: 'TransportCubeProvider'
    );

    return List.unmodifiable(filteredCubes);
  }
  TransportCubeDetails? get selectedCubeDetails => _selectedCubeDetails;
  Set<int> get selectedCubes => Set.unmodifiable(_selectedCubes);
  Set<int> get selectedCubeIds => selectedCubes;

  // Obtiene detalles sin notificar a listeners (para FutureBuilder en pantallas)
  Future<TransportCubeDetails> fetchCubeDetailsRaw(int cubeId, {bool suppressAuthHandling = true}) async {
    final resp = await _service.getTransportCubeDetails(cubeId, suppressAuthHandling: suppressAuthHandling);
    if (!resp.isSuccessful || resp.content == null) {
      throw Exception(resp.message ?? 'No se pudo obtener detalles del cubo');
    }
    return resp.content!;
  }

  // Carga los detalles de un cubo (mantenemos por compatibilidad, usa cache interna)
  Future<void> loadCubeDetails(int cubeId) async {
    // Evitar recargas innecesarias bajo varias condiciones
    if (_loadingDetails[cubeId] == true) {
      developer.log(
        'Skipping loadCubeDetails - Request already in progress for cube $cubeId',
        name: 'TransportCubeProvider',
      );
      return;
    }

    if (_isLoading) {
      developer.log('Skipping loadCubeDetails - Already loading', name: 'TransportCubeProvider');
      return;
    }

    // Si ya tenemos los detalles del mismo cubo y todo está correcto, evitar recarga
    final currentDetails = _selectedCubeDetails;
    if (currentDetails != null && 
        currentDetails.transportCube.id == cubeId && 
        _errorMessage == null) {
      developer.log(
        'Skipping loadCubeDetails - Already have details for cube $cubeId',
        name: 'TransportCubeProvider',
      );
      return;
    }

    // Si los detalles son del mismo cubo pero hay error, limpiar error antes de recargar
    if (currentDetails?.transportCube.id == cubeId) {
      _errorMessage = null;
    }

    try {
      bool shouldNotify = !_isLoading;
      _loadingDetails[cubeId] = true;
      _isLoading = true;
      if (shouldNotify) {
        notifyListeners();
      }

      developer.log('Loading details for cube $cubeId', name: 'TransportCubeProvider');
      final response = await _service.getTransportCubeDetails(cubeId, suppressAuthHandling: true);
      
      if (response.isSuccessful && response.content != null) {
        final TransportCubeDetails newDetails = response.content!;
        final hasChanged = _selectedCubeDetails?.transportCube.id != newDetails.transportCube.id ||
                         _selectedCubeDetails?.guides.length != newDetails.guides.length ||
                         _selectedCubeDetails?.transportCube.state != newDetails.transportCube.state;

        _selectedCubeDetails = newDetails;
        _errorMessage = null;

        developer.log(
          'Loaded cube details - State: ${newDetails.transportCube.state}, Guides: ${newDetails.guides.length}, Changed: $hasChanged',
          name: 'TransportCubeProvider',
        );
      } else {
        _errorMessage = response.message ?? 'No se pudo cargar los detalles del cubo';
        developer.log(
          'Failed to load cube details - Error: $_errorMessage',
          name: 'TransportCubeProvider',
        );
      }
    } catch (e, stackTrace) {
      _errorMessage = 'No se pudo cargar los detalles del cubo';
      developer.log(
        'Error loading cube details',
        name: 'TransportCubeProvider',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      _loadingDetails.remove(cubeId);
      _isLoading = false;
      notifyListeners();
    }
  }

  // Crea un nuevo cubo
  Future<ApiResponse<NewTransportCubeResponseGenericResponse>> createTransportCube(List<String> guides) async {
    if (_isLoading) return ApiResponse.error(message: 'Operación en curso');

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Capturar IDs actuales antes de crear para poder detectar el nuevo cubo
      final Set<int> previousIds = _cubes.map((c) => c.id).toSet();

      AppLogger.log(
        'Creando cubo con ${guides.length} guías',
        source: 'TransportCubeProvider'
      );

      final request = op.NewTransportCubeRequest(
        guides: guides,
      );
      final response = await _service.createTransportCube(request);

      if (response.isSuccessful && response.content?.code == 0) {
        // Obtener el ID del cubo creado
        final newCubeId = response.content?.content?.id;
        AppLogger.log(
          'Cubo creado exitosamente con ID: $newCubeId',
          source: 'TransportCubeProvider'
        );
        AppLogger.log(
          'Cubo creado exitosamente, iniciando polling para detectar el nuevo cubo',
          source: 'TransportCubeProvider'
        );

        // Hasta 3 intentos con pequeña espera para detectar el nuevo cubo
        const attempts = 3;
        const delayMs = 600;
        bool found = false;

        for (int i = 0; i < attempts; i++) {
          await loadCubes(force: true);
          // Detectar IDs nuevos
          final Set<int> currentIds = _cubes.map((c) => c.id).toSet();
          final Set<int> diff = currentIds.difference(previousIds);

          AppLogger.log(
            'Post-create polling attempt \'${i + 1}\' - New IDs detected: ${diff.join(", ")}',
            source: 'TransportCubeProvider'
          );

          if (diff.isNotEmpty) {
            found = true;
            _lastMessageDetail = 'Cubo creado exitosamente con ID ${diff.first}';
            break;
          }

          await Future.delayed(const Duration(milliseconds: delayMs));
        }

        if (!found) {
          AppLogger.log(
            'Polling terminado: no se detectó un nuevo cubo en la lista. Puede ser retardo del backend o validación de negocio.',
            source: 'TransportCubeProvider'
          );
          // Mensaje para el usuario cuando no se detecta el cubo nuevo
          _lastMessageDetail = '⚠️ El backend confirmó la creación pero el cubo aún no aparece en la lista. '
            'Esto puede deberse a que la guía no cumple con los requisitos necesarios o a un retardo del sistema. '
            'Intente refrescar la lista en unos segundos.';
        }

        _errorMessage = null;
        return response;
      }

      _errorMessage = response.messageDetail ?? 'No se pudo crear el cubo';
      return response;
    } catch (e) {
      _errorMessage = 'No se pudo crear el cubo';
      return ApiResponse.error(message: _errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cambia el estado de un cubo
  Future<bool> changeTransportCubeState(
    int cubeId,
    String newState,
  ) async {
    if (_isLoading) return false;

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

final request = op.ChangeTranportCubesStateRequest(
        transportCubeIds: [cubeId],
        newState: newState,
      );
      final response = await _service.changeTransportCubesState(request);

      if (response.isSuccessful) {
        await loadCubes();
        _errorMessage = null;
        _lastMessageDetail = response.messageDetail ?? response.message;
        return true;
      }
      // Verificar si es error de sesión
      _errorMessage = response.message ?? 'No se pudo actualizar el estado';
      return false;
    } catch (e) {
      _errorMessage = 'No se pudo actualizar el estado';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  /// Cambia el estado de múltiples cubos
  Future<ApiResponse<void>> changeSelectedCubesState(String newState) async {
    developer.log(
      'Processing selected cubes for state change:\n- Selected cubes: ${_selectedCubes.join(", ")}\n- New state: $newState',
      name: 'TransportCubeProvider',
    );

    if (_isLoading || _selectedCubes.isEmpty) {
      developer.log(
        'Cannot process - Loading: $_isLoading, Selected cubes empty: ${_selectedCubes.isEmpty}',
        name: 'TransportCubeProvider',
      );
      return ApiResponse.error(message: 'No hay cubos seleccionados para actualizar');
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Solo cambiar estado de los cubos
      final request = ChangeTranportCubesStateRequest(
        transportCubeIds: _selectedCubes.toList(),
        newState: newState,
      );
      
      final response = await _service.changeTransportCubesState(request);
      
      // Considerar código 60 como éxito también
      if (response.isSuccessful || (response.message?.contains('(60)') ?? false)) {
        _lastMessageDetail = response.messageDetail ?? response.message;
        _selectedCubes.clear();
        _errorMessage = null;
        
        // Solo recargar la lista actual para ver los cubos desaparecer
        await loadCubes(force: true);
        
        developer.log(
          'Successfully changed cube states to $newState - Message: ${response.messageDetail ?? response.message}',
          name: 'TransportCubeProvider',
        );
        return response;
      } else {
        _errorMessage = response.messageDetail ?? response.message ?? 'No se pudo actualizar el estado';
        developer.log('Failed to change cube states: ${response.message}', name: 'TransportCubeProvider');
        return response;
      }
    } catch (e) {
      _errorMessage = 'Error al procesar envío a tránsito';
      developer.log('Error in changeSelectedCubesState: $e', name: 'TransportCubeProvider');
      return ApiResponse.error(message: _errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cambia el filtro de estado
  void changeStateFilter(String newState) {
    if (_selectedState != newState) {
      developer.log('Changing UI state filter from $_selectedState to $newState', name: 'TransportCubeProvider');
      _selectedState = newState;
      _selectedCubes.clear();
      notifyListeners();
    } else {
      developer.log('UI state filter already at $newState', name: 'TransportCubeProvider');
    }
  }


  // Maneja la selección de cubos
  void toggleCubeSelection(int cubeId) {
    developer.log('Attempting to toggle cube selection - ID: $cubeId', name: 'TransportCubeProvider');
    
    // Validar que el cubo existe en la lista actual
    if (!_cubes.any((cube) => cube.id == cubeId)) {
      developer.log(
        'Error: Cube not found in current list - ID: $cubeId',
        name: 'TransportCubeProvider',
        error: 'Cube not found',
      );
      return;
    }

    final cube = _cubes.firstWhere((cube) => cube.id == cubeId);

    if (_selectedCubes.contains(cubeId)) {
      developer.log(
        'Deseleccionando cubo:\n- ID: $cubeId\n- Estado: ${cube.state}\n- Guías: ${cube.guides}',
        name: 'TransportCubeProvider',
      );
      _selectedCubes.remove(cubeId);
    } else {
      developer.log(
        'Seleccionando cubo:\n- ID: $cubeId\n- Estado: ${cube.state}\n- Guías: ${cube.guides}',
        name: 'TransportCubeProvider',
      );
      _selectedCubes.add(cubeId);
    }
    
    developer.log(
      'Total cubos seleccionados: ${_selectedCubes.length}\nIDs: ${_selectedCubes.join(", ")}',
      name: 'TransportCubeProvider',
    );
    
    notifyListeners();
  }

  // Limpia la selección
  void clearSelection() {
    if (_selectedCubes.isNotEmpty) {
      _selectedCubes.clear();
      notifyListeners();
    }
  }

  // Limpia el error
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  // Change current state and load cubes
  Future<void> changeState(String newState) async {
    developer.log('Changing state to $newState and loading cubes', name: 'TransportCubeProvider');
    changeStateFilter(newState);
    await loadCubes();
  }


  // Load cubes
  Future<void> loadCubes({bool force = false}) async {
    AppLogger.log(
      'Loading transport cubes - State: $_selectedState',
      source: 'TransportCubeProvider'
    );
    
    if (_isLoading && !force) {
      AppLogger.log(
        'Skip loading - Operation already in progress',
        source: 'TransportCubeProvider'
      );
      return;
    }
    
    try {
      // Si estamos forzando, no marcar _isLoading para no bloquear cargas paralelas controladas
      if (!force) {
        _isLoading = true;
        _errorMessage = null;
        notifyListeners();
      } else {
        _errorMessage = null;
      }

      // Los parámetros deben ser valores numéricos válidos y estar en PascalCase
      const page = 1;
      const itemsPerPage = 100; // Aumentar para reducir truncamiento al detectar nuevos cubos
      
      AppLogger.log(
        'Loading transport cubes with params:\n- Page: $page\n- ItemsPerPage: $itemsPerPage\n- State: $_selectedState',
        source: 'TransportCubeProvider'
      );

      final response = await _service.getTransportCubes(
        page: page,
        itemsPerPage: itemsPerPage,
        state: _selectedState,  // Usar el estado seleccionado actualmente
      );

      developer.log(
        'Cubes response received - Success: ${response.isSuccessful}, HasContent: ${response.content != null}',
        name: 'TransportCubeProvider',
      );

      if (response.isSuccessful && response.content != null) {
        _cubes = response.content!.registers;
        developer.log(
          'Load success:\n'
          '- Cubes loaded: ${_cubes.length}\n'
          '- Current state: $_selectedState\n'
          '- Response message: ${response.messageDetail ?? response.message}',
          name: 'TransportCubeProvider'
        );
        // Limpiar error explícitamente si tenemos datos
        _errorMessage = null;
        _lastMessageDetail = null;
      } else {
        _errorMessage = response.messageDetail ?? response.message ?? 'Error al cargar cubos';
        developer.log('Failed to load cubes - Error: $_errorMessage', name: 'TransportCubeProvider');
      }
    } catch (e, stackTrace) {
      _errorMessage = 'Error al cargar cubos';
      developer.log(
        'Error loading cubes',
        name: 'TransportCubeProvider',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      if (!force) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // Create cube alias
  Future<bool> createCube(List<String> guides) async {
    try {
      await createTransportCube(guides);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Verify and change transport cube state
  Future<bool> verifyAndChangeTransportCubeState(
    int cubeId,
    String newState,
  ) async {
    return await changeTransportCubeState(cubeId, newState);
  }

  // Get cube history (stub, serviced by backend in future)
  Future<List<String>> getCubeHistory(int cubeId) async {
    final response = await _service.getCubeHistory(cubeId);
    return response.content ?? [];
  }

  // Check if cube is selected
  bool isCubeSelected(int cubeId) {
    return _selectedCubes.contains(cubeId);
  }
  
  // Actualiza localmente el estado de cubos específicos (solo para navegación UI)
  // NO hace llamadas al backend - solo para que los cubos "se muevan" a otras pestañas
  void updateLocalCubeStates(List<int> cubeIds, String newState) {
    developer.log(
      'Updating local cube states for UI navigation:\n- Cubes: ${cubeIds.join(", ")}\n- New state: $newState',
      name: 'TransportCubeProvider',
    );
    
    bool stateChanged = false;
    
    for (final cubeId in cubeIds) {
      final cubeIndex = _cubes.indexWhere((cube) => cube.id == cubeId);
      if (cubeIndex != -1) {
        final currentCube = _cubes[cubeIndex];
        
        // Crear nueva instancia del cubo con estado actualizado
        final updatedCube = op.TransportCubeInfoAPI(
          id: currentCube.id,
          registerDateTime: currentCube.registerDateTime,
          state: newState, // Solo cambio de estado
          guides: currentCube.guides,
          stateLabel: TransportCubeState.getLabel(newState),
        );
        
        _cubes[cubeIndex] = updatedCube;
        stateChanged = true;
        
        developer.log(
          'Local state updated: Cube $cubeId from ${currentCube.state} to $newState',
          name: 'TransportCubeProvider',
        );
      }
    }
    
    if (stateChanged) {
      // Limpiar selección ya que los cubos se "movieron"
      _selectedCubes.clear();
      notifyListeners();
    }
  }
}
