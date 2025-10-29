import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import '../../../core/services/app_logger.dart';
import '../../../core/services/version_service.dart';
import '../services/auth_service.dart';
import '../models/auth_models.dart';
import '../../../core/services/secure_credentials_service.dart';

/// Provider para manejar la autenticación
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final SecureCredentialsService _secureStorage = SecureCredentialsService();
  
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
      // Verificar primero la versión
      final versionHeaders = VersionService.instance.versionHeaders;
      final versionResponse = VersionResponse.fromHeaders(versionHeaders);
      
      // Forzar actualización si es requerida
      if (versionResponse.updateRequired) {
        _loginData = null;
        _isAuthenticated = false;
        await _authService.logout();
        await _secureStorage.clearCredentials();
        notifyListeners();
        return;
      }
      
      final loginData = await _authService.restoreSession();
      if (loginData != null) {
        _loginData = loginData;
        _isAuthenticated = true;
        notifyListeners();
        
        // Validar que el token aún sea válido
        final isValid = await _authService.hasValidToken();
        if (!isValid) {
          // Intentar login silencioso con credenciales guardadas
          final saved = await _secureStorage.getCredentials();
          final username = saved['username'];
          final password = saved['password'];
          
          if (username != null && password != null) {
            developer.log('Token invalid, attempting silent login on app start', name: 'AuthProvider');
            final success = await login(username, password);
            if (!success) {
              await logout();
            }
          } else {
            _isAuthenticated = false;
            _loginData = null;
            notifyListeners();
          }
        }
      } else {
        // No hay sesión activa, intentar login silencioso
        final saved = await _secureStorage.getCredentials();
        final username = saved['username'];
        final password = saved['password'];
        
        if (username != null && password != null) {
          developer.log('No active session, attempting silent login', name: 'AuthProvider');
          await login(username, password);
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

      // Verificar si el error es por versión
      if (response.messageDetail?.contains('versión mínima') ?? false) {
        _error = response.messageDetail;
        // No limpiar credenciales ni el error para que se muestre el diálogo
        _isAuthenticated = false;
        _loginData = null;
        notifyListeners();
        return false;
      }

      AppLogger.log(
        'Login response received:\n- Success: ${response.isSuccessful}\n- Has Content: ${response.content != null}',
        source: 'AuthProvider'
      );

      if (response.isSuccessful && response.content != null) {
        _loginData = response.content;
        _isAuthenticated = true;
        _error = null;
        notifyListeners();
        
        // Guardar credenciales en almacenamiento seguro (login silencioso futuro)
        await _secureStorage.saveCredentials(username, password);
        
        AppLogger.log('Login successful - Token received', source: 'AuthProvider', type: 'SUCCESS');
        return true;
      } else {
        _error = response.messageDetail;
        AppLogger.error('Login failed', error: _error ?? 'No message detail provided', source: 'AuthProvider');
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
      // Limpiar credenciales del almacenamiento seguro
      await _secureStorage.clearCredentials();
      
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
        // Intentar login silencioso con credenciales guardadas
        final saved = await _secureStorage.getCredentials();
        final u = saved['username'];
        final p = saved['password'];
        if (u != null && p != null) {
          developer.log('Attempting silent login with stored credentials', name: 'AuthProvider');
          final silentOk = await login(u, p);
          _isAuthenticated = silentOk;
        }
        
        // Si aún no está autenticado, hacer logout
        if (!_isAuthenticated) {
          developer.log('Token invalid and silent login failed, logging out', name: 'AuthProvider');
          await logout();
        }
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
