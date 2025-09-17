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
                Text(
                  '¡Bienvenido${auth.loginData?.personFirstName != null ? ', ${auth.loginData!.personFirstName}' : ''}!',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                if (auth.loginData?.entityName != null) ...[
                  const SizedBox(height: 8),
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
            title: const Text('Despacho a Cliente'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/client-dispatch');
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar Sesión'),
            onTap: () {
              auth.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}