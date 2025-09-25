import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'core/observers/auth_lifecycle_observer.dart';
import 'core/config/api_config.dart';
import 'core/services/http_service.dart';
import 'core/services/storage_service.dart';
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

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() {
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
  late final GuideService guideService;
  late final TransportCubeService transportCubeService;
  late final GuideDetailsService guideDetailsService;
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
    httpService = HttpService(
      baseUrl: ApiConfig.baseUrl,
      onSessionExpired: () {
        // Por ahora no forzamos logout automático
        debugPrint('Session expired - skipping auto logout');
      },
    );
    
    // Servicios de negocio
    authService = AuthService(httpService, storageService);
    guideService = GuideService(httpService);
    transportCubeService = TransportCubeService(httpService);
    guideDetailsService = GuideDetailsService(httpService);
    
    // Configurar callback de refresh token después de tener el authService
    httpService.tokenRefreshCallback = () async {
      debugPrint('Token refresh needed - attempting refresh');
      return await authService.refreshTokenIfNeeded();
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
      WidgetsBinding.instance.removeObserver(_authObserver!);
      _authObserver = null;
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Inicializar observer de auth cuando el context esté disponible
    _authObserver ??= AuthLifecycleObserver(context);
    WidgetsBinding.instance.addObserver(_authObserver!);
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
      ],
      child: MaterialApp(
        title: 'GBI Logistics',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1976D2),
          ),
          useMaterial3: true,
        ),
        initialRoute: '/login',
        navigatorKey: appNavigatorKey,
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
