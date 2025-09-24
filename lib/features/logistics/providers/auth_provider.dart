import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import '../../../core/services/app_logger.dart';
import '../services/auth_service.dart';
import '../models/auth_models.dart';

/// Provider para manejar la autenticación
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  
  bool _isLoading = false;
  String? _error;
  LoginResponse? _loginData;
  bool _isAuthenticated = false;

  AuthProvider(this._authService) {
    // Intentar restaurar sesión al inicializar
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final loginData = await _authService.restoreSession();
      if (loginData != null) {
        _loginData = loginData;
        _isAuthenticated = true;
        notifyListeners();
        
        // Validar que el token aún sea válido, si no lo es, limpiar sin marcar la sesión como cerrada manualmente
        final isValid = await _authService.hasValidToken();
        if (!isValid) {
          _isAuthenticated = false;
          _loginData = null;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error restoring session: $e');
      await logout();
    }
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  LoginResponse? get loginData => _loginData;
  List<SubcourierInfo> get subcouriers => _loginData?.subcouriersInformation ?? [];
  DashboardData? get dashboardData => _loginData?.dashboardData;

  /// Realiza el login
  Future<bool> login(String username, String password) async {
    AppLogger.log('Attempting login', source: 'AuthProvider');
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final request = LoginRequest(
        username: username,
        password: password,
      );

      final response = await _authService.login(request);

      AppLogger.log(
        'Login response received:\n- Success: ${response.isSuccessful}\n- Has Content: ${response.content != null}',
        source: 'AuthProvider'
      );

      if (response.isSuccessful && response.content != null) {
        _loginData = response.content;
        _isAuthenticated = true;
        _error = null;
        notifyListeners();
        AppLogger.log('Login successful - Token received', source: 'AuthProvider', type: 'SUCCESS');
        return true;
      } else {
        _error = response.message;
        AppLogger.error('Login failed', error: _error, source: 'AuthProvider');
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      _error = e.toString();
      AppLogger.error(
        'Login error',
        error: e,
        stackTrace: stackTrace,
        source: 'AuthProvider'
      );
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cierra la sesión
  Future<void> logout() async {
    try {
      await _authService.logout();
    } finally {
      _isAuthenticated = false;
      _loginData = null;
      _error = null;
      notifyListeners();
    }
  }

  Future<void> checkAuthState() async {
    try {
      developer.log('Checking auth state...', name: 'AuthProvider');
      final hasValidToken = await _authService.hasValidToken();
      _isAuthenticated = hasValidToken;
      
      if (!hasValidToken) {
        // Si el token no es válido, hacer logout
        developer.log('Token invalid, logging out', name: 'AuthProvider');
        await logout();
      } else {
        developer.log('Token is valid', name: 'AuthProvider');
      }
    } catch (e) {
      developer.log('Error checking auth state: $e', name: 'AuthProvider');
      _isAuthenticated = false;
      await logout();
    }
    notifyListeners();
  }

  /// Actualiza los datos del dashboard
  Future<void> refreshDashboard() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Aquí se llamaría al endpoint de dashboard
      // Por ahora solo actualizamos UI para mostrar loading
      await Future.delayed(const Duration(seconds: 1));

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Limpia el error actual
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Asegura que el token esté fresco (refresco preventivo si aplica)
  Future<bool> ensureFreshToken() async {
    return await _authService.refreshTokenIfNeeded();
  }
}
