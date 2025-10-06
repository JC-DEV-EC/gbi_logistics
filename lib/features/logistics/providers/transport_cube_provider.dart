import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

import '../../../core/models/api_response.dart';
import '../services/transport_cube_service.dart';
import '../models/transport_cube_state.dart';
import '../models/cube_type.dart';
import '../models/transport_cube_details.dart';
import '../models/operation_models.dart' as op;
import '../models/operation_models.dart';

/// Provider para manejo local de cubos de transporte
class TransportCubeProvider extends ChangeNotifier {
  // Estado
  bool _isLoading = false;
  String? _errorMessage;
  String? _lastMessageDetail;
  String _selectedState = TransportCubeState.created; // Estado inicial
  final Map<int, bool> _loadingDetails = {};
  List<op.TransportCubeInfoAPI> _cubes = [];
  TransportCubeDetails? _selectedCubeDetails;
  final Set<int> _selectedCubes = {};
  final TransportCubeService _service;

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
      name: 'TransportCubeProvider',
    );

    final filteredCubes =
    _cubes.where((cube) => cube.state == _selectedState).toList();

    developer.log(
      'Getting cubes:\n'
          '- Total cubes: ${_cubes.length}\n'
          '- Selected state: $_selectedState\n'
          '- Filtered cubes: ${filteredCubes.length}\n'
          '- Error message: $_errorMessage',
      name: 'TransportCubeProvider',
    );

    return List.unmodifiable(filteredCubes);
  }

  TransportCubeDetails? get selectedCubeDetails => _selectedCubeDetails;
  Set<int> get selectedCubes => Set.unmodifiable(_selectedCubes);
  Set<int> get selectedCubeIds => selectedCubes;

  // Obtiene detalles sin notificar a listeners
  Future<TransportCubeDetails> fetchCubeDetailsRaw(int cubeId,
      {bool suppressAuthHandling = true}) async {
    final resp = await _service.getTransportCubeDetails(
      cubeId,
      suppressAuthHandling: suppressAuthHandling,
    );

    if (!resp.isSuccessful || resp.content == null) {
      throw Exception(resp.messageDetail ?? 'No se pudo obtener detalles');
    }
    return resp.content!;
  }

  // Carga los detalles de un cubo
  Future<void> loadCubeDetails(int cubeId) async {
    if (_loadingDetails[cubeId] == true) return;
    if (_isLoading) return;

    final currentDetails = _selectedCubeDetails;
    if (currentDetails != null &&
        currentDetails.transportCube.id == cubeId &&
        _errorMessage == null) {
      return;
    }

    if (currentDetails?.transportCube.id == cubeId) {
      _errorMessage = null;
    }

    try {
      bool shouldNotify = !_isLoading;
      _loadingDetails[cubeId] = true;
      _isLoading = true;
      if (shouldNotify) notifyListeners();

      final response =
      await _service.getTransportCubeDetails(cubeId, suppressAuthHandling: true);

      if (response.isSuccessful && response.content != null) {
        final newDetails = response.content!;
        _selectedCubeDetails = newDetails;
        _errorMessage = null;
      } else {
        _errorMessage = response.messageDetail;
      }
    } catch (e, stackTrace) {
      _errorMessage = null;
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

  // Crear cubo
  Future<ApiResponse<NewTransportCubeResponseGenericResponse>>
  createTransportCube(List<String> guides, CubeType type) async {
    if (_isLoading) return ApiResponse.error(messageDetail: 'Operación en curso');

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final previousIds = _cubes.map((c) => c.id).toSet();
      final request = op.NewTransportCubeRequest(guides: guides, type: type);
      final response = await _service.createTransportCube(request);

      if (response.isSuccessful && response.content?.code == 0) {
        const attempts = 3;
        const delayMs = 600;
        bool found = false;

        for (int i = 0; i < attempts; i++) {
          await loadCubes(force: true);
          final currentIds = _cubes.map((c) => c.id).toSet();
          final diff = currentIds.difference(previousIds);

          if (diff.isNotEmpty) {
            found = true;
            _lastMessageDetail = 'Cubo creado con ID ${diff.first}';
            break;
          }
          await Future.delayed(const Duration(milliseconds: delayMs));
        }

        if (!found) {
          _lastMessageDetail =
          'Confirmado pero aún no aparece en la lista. Refresque más tarde.';
        }

        _errorMessage = null;
        return response;
      }

      _errorMessage = response.messageDetail;
      return response;
    } catch (e) {
      _errorMessage = null;
      return ApiResponse.error(messageDetail: null);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cambiar estado
  Future<bool> changeTransportCubeState(int cubeId, String newState) async {
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
        // No generar mensajes locales, solo usar messageDetail
        _errorMessage = null;
        _lastMessageDetail = response.messageDetail;
        await loadCubes();
        return true;
      }

      _errorMessage = response.messageDetail;
      return false;
    } catch (_) {
      _errorMessage = null;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cambiar estado de varios cubos
  Future<ApiResponse<void>> changeSelectedCubesState(String newState) async {
    if (_isLoading || _selectedCubes.isEmpty) {
      return ApiResponse.error(messageDetail: 'No hay cubos seleccionados');
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final request = ChangeTranportCubesStateRequest(
        transportCubeIds: _selectedCubes.toList(),
        newState: newState,
      );

      final response = await _service.changeTransportCubesState(request);

      if (response.isSuccessful) {
        _lastMessageDetail = response.messageDetail;
        _selectedCubes.clear();
        _errorMessage = null;
        await loadCubes(force: true);
        return response;
      } else {
        _errorMessage = response.messageDetail;
        return response;
      }
    } catch (_) {
      _errorMessage = null;
      return ApiResponse.error(messageDetail: null);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filtros y selección
  void changeStateFilter(String newState) {
    if (_selectedState != newState) {
      _selectedState = newState;
      _selectedCubes.clear();
      notifyListeners();
    }
  }

  void toggleCubeSelection(int cubeId) {
    if (!_cubes.any((cube) => cube.id == cubeId)) return;

    if (_selectedCubes.contains(cubeId)) {
      _selectedCubes.remove(cubeId);
    } else {
      _selectedCubes.add(cubeId);
    }
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedCubes.isNotEmpty) {
      _selectedCubes.clear();
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<void> changeState(String newState) async {
    changeStateFilter(newState);
    await loadCubes();
  }

  // Cargar cubos
  Future<void> loadCubes({bool force = false}) async {
    if (_isLoading && !force) return;

    try {
      if (!force) {
        _isLoading = true;
        _errorMessage = null;
        notifyListeners();
      }

      const page = 1;
      const itemsPerPage = 100;

      final response = await _service.getTransportCubes(
        page: page,
        itemsPerPage: itemsPerPage,
        state: _selectedState,
      );

      if (response.isSuccessful && response.content != null) {
        _cubes = response.content!.registers.map((cube) {
          return op.TransportCubeInfoAPI(
            id: cube.id,
            registerDateTime: cube.registerDateTime,
            state: cube.state,
            guides: cube.guides,
            stateLabel: TransportCubeState.getLabel(cube.state),
            type: cube.type,
            typeLabel: cube.typeLabel,
            operatorName: cube.operatorName,
          );
        }).toList();
        _errorMessage = null;
        _lastMessageDetail = null;
      } else {
        _errorMessage = response.messageDetail;
      }
    } catch (e, stackTrace) {
      _errorMessage = null;
      developer.log('Error loading cubes',
          name: 'TransportCubeProvider', error: e, stackTrace: stackTrace);
    } finally {
      if (!force) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // Alias
  Future<bool> createCube(List<String> guides, {required CubeType type}) async {
    try {
      await createTransportCube(guides, type);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> verifyAndChangeTransportCubeState(
      int cubeId, String newState) async {
    return await changeTransportCubeState(cubeId, newState);
  }

  Future<List<String>> getCubeHistory(int cubeId) async {
    final response = await _service.getCubeHistory(cubeId);
    return response.content ?? [];
  }

  bool isCubeSelected(int cubeId) => _selectedCubes.contains(cubeId);

  void updateLocalCubeStates(List<int> cubeIds, String newState) {
    bool stateChanged = false;

    for (final cubeId in cubeIds) {
      final cubeIndex = _cubes.indexWhere((cube) => cube.id == cubeId);
      if (cubeIndex != -1) {
        final currentCube = _cubes[cubeIndex];
        final updatedCube = op.TransportCubeInfoAPI(
          id: currentCube.id,
          registerDateTime: currentCube.registerDateTime,
          state: newState,
          guides: currentCube.guides,
          stateLabel: TransportCubeState.getLabel(newState),
          type: currentCube.type,
          typeLabel: currentCube.typeLabel,
          operatorName: currentCube.operatorName,
        );
        _cubes[cubeIndex] = updatedCube;
        stateChanged = true;
      }
    }

    if (stateChanged) {
      _selectedCubes.clear();
      notifyListeners();
    }
  }

  // Despachar cubos seleccionados
  Future<ApiResponse<GenericOperationResponseGenericResponse>>
  dispatchSelectedCubesToClient() async {
    if (_isLoading || _selectedCubes.isEmpty) {
      return ApiResponse.error(messageDetail: 'No hay cubos seleccionados');
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response =
      await _service.dispatchCubeToClient(_selectedCubes.toList());

      // Mostrar mensajes exclusivamente desde messageDetail
      _lastMessageDetail = response.messageDetail;

      if (response.isSuccessful) {
        _selectedCubes.clear();
        _errorMessage = null;
        await loadCubes(force: true);
        return response;
      } else {
        _errorMessage = response.messageDetail;
        return response;
      }
    } catch (_) {
      _errorMessage = null;
      return ApiResponse.error(messageDetail: null);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Verificación por tipo de cubo para mostrar acción de despacho
  bool canDispatchToClientByType(CubeType type) {
    return type == CubeType.toDispatchToSubcourier || type == CubeType.toDispatchToClient;
  }
}
