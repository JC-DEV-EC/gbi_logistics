import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../presentation/helpers/error_helper.dart';
import '../presentation/widgets/loading_indicator.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              auth.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
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
              children: dashboardData.guideStadistics.map((stat) {
                return Card(
                  child: InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/guides',
                        arguments: stat.status,
                      );
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
                              stat.count.toString(),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Flexible(
                            child: Text(
                              stat.status ?? 'Sin estado',
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
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 24),

        // Accesos rápidos
        Text(
          'Accesos Rápidos',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.local_shipping_outlined),
                title: const Text('Despacho en Aduana'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(context, '/customs-dispatch');
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.directions_run),
                title: const Text('Tránsito a Bodega'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(context, '/warehouse-transit');
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.warehouse_outlined),
                title: const Text('Recepción en Bodega'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(context, '/warehouse-reception');
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Despacho a Cliente'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(context, '/client-dispatch');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
