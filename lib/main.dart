import 'package:flutter/material.dart';
import 'features/logistics/models/cube_type.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'core/observers/auth_lifecycle_observer.dart';
import 'core/config/api_config.dart';
import 'core/services/http_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/version_service.dart';
import 'core/services/secure_credentials_service.dart';
import 'core/services/app_update_service.dart';
import 'features/logistics/providers/auth_provider.dart';
import 'features/logistics/models/operation_models.dart';
import 'features/logistics/providers/guide_provider.dart';
import 'features/logistics/providers/transport_cube_provider.dart';
import 'features/logistics/services/auth_service.dart';
import 'features/logistics/services/guide_service.dart';
import 'features/logistics/services/transport_cube_service.dart';
import 'features/logistics/screens/login_screen.dart';
import 'features/logistics/screens/dashboard_screen.dart';
import 'features/logistics/screens/customs_dispatch_screen.dart';
import 'features/logistics/screens/warehouse_transit_screen.dart';
import 'features/logistics/screens/warehouse_reception_screen.dart';
import 'features/logistics/screens/client_dispatch_screen.dart';
import 'features/logistics/screens/customs_dispatch_details_screen.dart';
import 'features/logistics/screens/warehouse_transit_details_screen.dart';
import 'features/logistics/screens/warehouse_reception_details_screen.dart';
import 'features/logistics/screens/client_dispatch_details_screen.dart';
import 'features/logistics/screens/new_transport_cube_screen.dart';
import 'features/logistics/services/guide_details_service.dart';
import 'features/logistics/screens/guide_scanner_details_screen.dart';
import 'features/logistics/services/guide_validation_service.dart';
import 'features/logistics/providers/guide_validation_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializar servicio de versión antes de renderizar UI
  await VersionService.instance.initialize();
  
  // Capturar errores no manejados
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.toString()}');
  };

  // Mostrar error overlay en debug
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        child: Container(
          color: Colors.white,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error: ${details.exception}',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final StorageService storageService;
  late final HttpService httpService;
  late final AuthService authService;
  late final SecureCredentialsService secureCredentialsService;
  late final GuideService guideService;
  late final TransportCubeService transportCubeService;
  late final GuideDetailsService guideDetailsService;
  late final GuideValidationService guideValidationService;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  Timer? _tokenRefreshTimer;
  AuthLifecycleObserver? _authObserver;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    // Registrar observer de ciclo de vida global
    WidgetsBinding.instance.addObserver(this);
  }

  void _initializeServices() {
    // Servicios base
    storageService = StorageService();
    secureCredentialsService = SecureCredentialsService();
    httpService = HttpService(
      baseUrl: ApiConfig.baseUrl,
      onSessionExpired: () {
        // Por ahora no forzamos logout automático
        debugPrint('Session expired - skipping auto logout');
      },
    );
    
    // Servicios de negocio
    authService = AuthService(httpService, storageService, secureCredentialsService);
    guideService = GuideService(httpService);
    transportCubeService = TransportCubeService(httpService);
    guideDetailsService = GuideDetailsService(httpService);
    guideValidationService = GuideValidationService(httpService);
    
    // Configurar callback de refresh token después de tener el authService
    httpService.tokenRefreshCallback = () async {
      debugPrint('Token refresh needed - attempting refresh');
      return await authService.refreshTokenIfNeeded();
    };
    
    // Configurar callback de versión
    httpService.versionCheckCallback = (versionResponse) {
      final context = _navigatorKey.currentContext;
      AppUpdateService.instance.handleVersionResponse(context, versionResponse);
    };
    
    // Verificación/refresh periódico del token
    _startTokenRefreshTimer();
  }

  void _startTokenRefreshTimer() {
    // Intento inicial al arrancar
    unawaited(authService.refreshTokenIfNeeded());
    // Programar verificación periódica
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = Timer.periodic(
      ApiConfig.tokenCheckInterval,
      (_) => authService.refreshTokenIfNeeded(),
    );
  }

  @override
  void dispose() {
    _tokenRefreshTimer?.cancel();
    if (_authObserver != null) {
      _authObserver!.dispose();
      WidgetsBinding.instance.removeObserver(_authObserver!);
      _authObserver = null;
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_authObserver == null) {
      // Esperar a que el árbol esté montado para tener acceso al contexto correcto
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        
        _authObserver = AuthLifecycleObserver(() {
          // Usar el contexto del navigator para asegurar acceso a los providers
          final ctx = _navigatorKey.currentContext;
          if (ctx == null) throw Exception('Navigator context not available');
          return ctx;
        });
        
        WidgetsBinding.instance.addObserver(_authObserver!);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('App resumed - checking auth state');
      unawaited(authService.refreshTokenIfNeeded());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Verificar versión al inicio
    final versionHeaders = VersionService.instance.versionHeaders;
    final versionResponse = VersionResponse.fromHeaders(versionHeaders);
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authService),
        ),
        ChangeNotifierProvider<GuideProvider>(
          create: (_) => GuideProvider(guideService),
        ),
        ChangeNotifierProvider<TransportCubeProvider>(
          create: (_) => TransportCubeProvider(transportCubeService)..loadCubes(),
        ),
        Provider<GuideDetailsService>(
          create: (_) => guideDetailsService,
        ),
        ChangeNotifierProvider<GuideValidationProvider>(
          create: (_) => GuideValidationProvider(guideValidationService),
        ),
      ],
      child: MaterialApp(
        title: 'GBI Logistics',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1976D2),
          ),
          useMaterial3: true,
        ),
        // Manejar la versión requerida antes de cualquier navegación
        builder: (context, child) {
          if (versionResponse.updateRequired) {
            // Mostrar diálogo de actualización forzada
            WidgetsBinding.instance.addPostFrameCallback((_) {
              AppUpdateService.instance.handleVersionResponse(context, versionResponse);
            });
            // Mostrar pantalla en blanco mientras se muestra el diálogo
            return const Material(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          return child ?? const SizedBox();
        },
        initialRoute: '/login',
        navigatorKey: _navigatorKey,
        onGenerateRoute: (settings) {
          // Extraer argumentos si existen
          final args = settings.arguments;

          switch (settings.name) {
            case '/login':
              return MaterialPageRoute(
                builder: (_) => const LoginScreen(),
              );

            case '/dashboard':
              return MaterialPageRoute(
                builder: (_) => const DashboardScreen(),
              );

            case '/customs-dispatch':
              return MaterialPageRoute(
                builder: (_) => const CustomsDispatchScreen(),
              );

            case '/warehouse-transit':
              return MaterialPageRoute(
                builder: (_) => const WarehouseTransitScreen(),
              );

            case '/warehouse-reception':
              return MaterialPageRoute(
                builder: (_) => const WarehouseReceptionScreen(),
              );

            case '/client-dispatch':
              return MaterialPageRoute(
                builder: (_) => const ClientDispatchScreen(),
              );

            case '/transport-cube/new':
              return MaterialPageRoute(
                builder: (_) => const NewTransportCubeScreen(),
              );

            case '/transport-cube/details':
              if (args is! int) {
                return MaterialPageRoute(
                  builder: (_) => const DashboardScreen(),
                );
              }

              return MaterialPageRoute(
                builder: (context) {
                  final provider = Provider.of<TransportCubeProvider>(
                    context,
                    listen: false,
                  );
                  
                  // Buscar el cubo en la lista actual
                  final cube = provider.cubes.firstWhere(
                    (cube) => cube.id == args,
                    orElse: () {
                      // Si no encontramos el cubo, no lo cargamos aquí
                      // La pantalla de detalles se encargará de la carga inicial
                      // Retornamos un cubo dummy para que no falle la navegación
                      return TransportCubeInfoAPI(
                        id: args,
                        registerDateTime: DateTime.now(),
                        state: 'Created',
                        guides: 0,
                        type: CubeType.transitToWarehouse,
                        stateLabel: 'Despachado de Aduana',
                      );
                    },
                  );

                  switch (cube.state) {
                    case 'Created':
                      return CustomsDispatchDetailsScreen(
                        cubeId: args,
                      );
                    case 'Sent':
                      return WarehouseTransitDetailsScreen(
                        cubeId: args,
                      );
                    case 'Downloading':
                      return WarehouseReceptionDetailsScreen(
                        cubeId: args,
                      );
                    case 'Downloaded':
                      return ClientDispatchDetailsScreen(
                        cubeId: args,
                      );
                    default:
                      return const DashboardScreen();
                  }
                },
              );

            case '/guide-scanner':
              return MaterialPageRoute(
                builder: (_) => const GuideScannerDetailsScreen(),
              );
            }

            return MaterialPageRoute(
              builder: (_) => const DashboardScreen(),
            );
        },
      ),
    );
  }
}
