import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/auth_models.dart';
import '../presentation/helpers/error_helper.dart';
import '../presentation/widgets/loading_indicator.dart';
import '../presentation/widgets/app_drawer.dart';

/// Pantalla principal del dashboard
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Usar addPostFrameCallback para evitar setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDashboard();
    });
  }

  Future<void> _refreshDashboard() async {
    await context.read<AuthProvider>().refreshDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: auth.isLoading
            ? const LoadingIndicator(
          message: 'Cargando dashboard...',
        )
            : auth.error != null
            ? ErrorHelper.buildErrorWidget(
          error: auth.error!,
          onRetry: _refreshDashboard,
        )
            : _buildDashboard(context),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final dashboardData = auth.dashboardData;

    if (dashboardData == null) {
      return const Center(
        child: Text('No hay datos disponibles'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        // Información del usuario
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '¡Bienvenido${auth.loginData?.personFirstName != null ? ', ${auth.loginData!.personFirstName}' : ''}!',
                  style: theme.textTheme.titleLarge,
                ),
                if (auth.loginData?.entityName != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    auth.loginData!.entityName!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),


        // Estadísticas de guías
        Text(
          'Estadísticas de Guías',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                // Mostrar todos los estados importantes, incluso cuando estén en 0
                ...[  // Lista de estados principales que siempre queremos mostrar
                  'Despachado de Aduana',
                  'Recibido en Bodega Local',
                  'Tránsito a Bodega',
                  'Listo para Entrega',
                ].map((estado) => _buildStatCard(
                  context,
                  estado,
                  dashboardData.guideStadistics
                    .firstWhere(
                      (stat) => stat.status == estado,
                      orElse: () => GuideStateStatistics(status: estado, count: 0)
                    ).count,
                  '/guides',
                )),
                // Mostrar otros estados si existen y no son los principales
                ...dashboardData.guideStadistics
                  .where((stat) => ![  // Excluir los estados principales
                    'Despachado de Aduana',
                    'Recibido en Bodega Local',
                    'Tránsito a Bodega',
                    'Listo para Entrega',
                    'Despacho en Aduana',  // Excluir explícitamente este estado
                  ].contains(stat.status))
                  .map((stat) => _buildStatCard(
                    context,
                    stat.status ?? 'Sin estado',
                    stat.count,
                    '/guides',
                  )),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, int count, String route) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, route, arguments: title);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  count.toString(),
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
