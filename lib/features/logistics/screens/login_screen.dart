import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../../../core/presentation/widgets/logging_state.dart';
import '../../../core/presentation/widgets/login_background.dart';
import '../presentation/helpers/error_helper.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/services/app_update_service.dart';
import '../../../core/services/version_service.dart';

/// Pantalla de login
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends LoggingState<LoginScreen> {
  @override
  String get screenName => 'LoginScreen';

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    logState('Checking authentication state');
    final authProvider = context.read<AuthProvider>();
    await authProvider.checkAuthState();

    if (mounted && authProvider.isAuthenticated) {
      logState('User already authenticated');
      logNavigation('/dashboard');
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      logState('User not authenticated');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _handleSubmit() async {
    logButton('Login Submit');
    logState('Starting login submission');

    if (!_formKey.currentState!.validate()) {
      logError('Form validation failed');
      return;
    }

    // Verificar versión antes de hacer login
    final versionHeaders = VersionService.instance.versionHeaders;
    final versionResponse = VersionResponse.fromHeaders(versionHeaders);
    
    if (versionResponse.updateRequired) {
      final needsUpdate = await AppUpdateService.instance.checkVersionBeforeLogin(
        context,
        versionResponse,
      );
      if (needsUpdate) {
        logState('Login blocked due to outdated app version');
        return;
      }
    }

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    logState('Attempting login with username: $username');

    final success = await context.read<AuthProvider>().login(
      username,
      password,
    );

    if (success && mounted) {
      developer.log('Login successful - Navigating to dashboard',
          name: 'LoginScreen');
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      developer.log('Login failed', name: 'LoginScreen');

      if (mounted) {
        final error = context.read<AuthProvider>().error;
        developer.log('Login error message: $error', name: 'LoginScreen');
        
        if (error != null && error.isNotEmpty) {
          // Si el error es de versión, mostrar diálogo de actualización
          if (error.contains('versión mínima')) {
            developer.log('VERSION ERROR DETECTED - Showing update dialog', name: 'LoginScreen');
            logState('Showing update dialog due to version error from backend');
            AppUpdateService.instance.handleVersionResponse(
              context,
              VersionResponse(
                updateRequired: true,
                updateMessage: error,
              ),
            );
            developer.log('Update dialog triggered', name: 'LoginScreen');
          } else {
            developer.log('Normal error - Showing snackbar', name: 'LoginScreen');
            // Para otros errores, mostrar snackbar normal
            MessageHelper.showIconSnackBar(
              context,
              message: error,
              isSuccess: false,
            );
          }
        } else {
          developer.log('Error is null or empty', name: 'LoginScreen');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: LoginBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo y texto con layout flexible
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo principal con altura flexible
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.5,
                      height: 160,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                Text(
                      'Bienvenido!',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ingrese datos personales \nde su cuenta de empleado',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // Card con formulario
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Inicio de sesión',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Usuario
                          TextFormField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Usuario',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            textInputAction: TextInputAction.next,
                            onChanged: (value) {
                              logTextInput('username', value);
                              context.read<AuthProvider>().clearError();
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingrese su usuario';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Contraseña
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  logButton('Toggle Password Visibility');
                                  _togglePasswordVisibility();
                                },
                              ),
                            ),
                            onChanged: (value) {
                              logTextInput('password', '*' * value.length);
                              context.read<AuthProvider>().clearError();
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingrese su contraseña';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _handleSubmit(),
                          ),
                          const SizedBox(height: 24),

                          // Botón de login
                          SizedBox(
                            height: 50,
                            child: FilledButton(
                              onPressed: auth.isLoading ? null : _handleSubmit,
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: auth.isLoading
                                  ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Text('Ingresar'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
