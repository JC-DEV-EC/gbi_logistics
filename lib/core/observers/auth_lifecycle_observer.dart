import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../features/logistics/providers/auth_provider.dart';
import '../services/app_logger.dart';

class AuthLifecycleObserver with WidgetsBindingObserver {
  final BuildContext Function() getContext;
  bool _disposed = false;

  AuthLifecycleObserver(this.getContext);

  void dispose() {
    _disposed = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed && !_disposed) {
      AppLogger.log(
        'App resumed - Refreshing authentication state',
        source: 'AuthLifecycleObserver'
      );
      
      try {
        final ctx = getContext();
        // Usar Provider.of para acceso más seguro
        final auth = Provider.of<AuthProvider>(ctx, listen: false);
        // Intentar refrescar token sin forzar logout
        final refreshed = await auth.ensureFreshToken();
        
        if (refreshed) {
          AppLogger.log(
            'Token refreshed successfully',
            source: 'AuthLifecycleObserver',
            type: 'SUCCESS'
          );
        }
        
        // Validar estado actual sin forzar logout
        await auth.checkAuthState();
      } catch (e) {
        AppLogger.error(
          'Error refreshing auth state on resume',
          error: e,
          source: 'AuthLifecycleObserver'
        );
      }
    }
  }
}