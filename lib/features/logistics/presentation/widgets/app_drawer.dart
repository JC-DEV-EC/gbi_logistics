import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Imagen del courier
                if (auth.loginData?.courierImageUrl != null && 
                    auth.loginData!.courierImageUrl!.isNotEmpty) ...[
                  Center(
                    child: SizedBox(
                      height: 50,
                      child: Image.network(
                        auth.loginData!.courierImageUrl!,
                        height: 50,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            height: 50,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return CircleAvatar(
                            radius: 28,
                            backgroundColor: theme.colorScheme.onPrimary,
                            child: Icon(
                              Icons.person,
                              size: 32,
                              color: theme.colorScheme.primary,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ] else ...[
                  Center(
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.onPrimary,
                      child: Icon(
                        Icons.person,
                        size: 32,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  '¡Bienvenido${auth.loginData?.personFirstName != null ? ', ${auth.loginData!.personFirstName}' : ''}!',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                if (auth.loginData?.entityName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    auth.loginData!.entityName!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/dashboard');
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.local_shipping_outlined),
            title: const Text('Despacho en Aduana'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/customs-dispatch');
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.warehouse_outlined),
            title: const Text('Recepción en Bodega'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/warehouse-reception');
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Despacho en Bodega'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/client-dispatch');
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: const Text('Consultar Guía'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/guide-scanner');
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar Sesión'),
            onTap: () async {
              // Mostrar diálogo de confirmación
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cerrar Sesión'),
                  content: const Text('¿Estás seguro que deseas cerrar sesión?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Cerrar Sesión'),
                    ),
                  ],
                ),
              );

              if (confirmed ?? false) {
                // Cerrar el drawer
                Navigator.pop(context);
                // Cerrar sesión y limpiar credenciales
                await auth.logout();
                // Navegar al login reemplazando toda la pila de navegación
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false, // Esto elimina todas las rutas anteriores
                );
              }
            },
          ),
        ],
      ),
    );
  }
}