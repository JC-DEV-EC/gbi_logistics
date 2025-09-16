import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/guide_provider.dart';
import '../presentation/widgets/client_dispatch_list_screen.dart';
import '../presentation/widgets/client_dispatch_scan_box.dart';

/// Pantalla para despacho a cliente
class ClientDispatchScreen extends StatefulWidget {
  const ClientDispatchScreen({super.key});

  @override
  State<ClientDispatchScreen> createState() => _ClientDispatchScreenState();
}

class _ClientDispatchScreenState extends State<ClientDispatchScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Despacho a Cliente'),
      ),
      body: Consumer2<GuideProvider, AuthProvider>(
        builder: (context, guideProvider, authProvider, _) {
          return Column(
            children: [
              _buildCourierSelector(guideProvider, authProvider),
              _buildScanBox(guideProvider),
              const Divider(height: 1),
              _buildErrorMessage(guideProvider),
              _buildGuideList(),
            ],
          );
        },
      ),
    );
  }

  /// Selector de mensajero
  Widget _buildCourierSelector(
      GuideProvider guideProvider,
      AuthProvider authProvider,
      ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) => DropdownButtonFormField<int>(
          isExpanded: true,  // Permitir que el dropdown use todo el ancho disponible
          decoration: const InputDecoration(
            labelText: 'Seleccionar Mensajero',
            border: OutlineInputBorder(),
          ),
          value: guideProvider.selectedSubcourierId,
          items: [
            for (final subcourier in authProvider.subcouriers)
              DropdownMenuItem(
                value: subcourier.id,
                child: Text(
                  subcourier.name ?? 'Sin nombre',
                  overflow: TextOverflow.ellipsis,  // Truncar texto si es muy largo
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) {
              guideProvider.setSelectedSubcourier(value);
            }
          },
        ),
      ),
    );
  }

  /// Box de escaneo en la parte superior
  Widget _buildScanBox(GuideProvider guideProvider) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: guideProvider.isLoading
          ? const LinearProgressIndicator()
          : const ClientDispatchScanBox(),
    );
  }

  /// Mensaje de error (si existe)
  Widget _buildErrorMessage(GuideProvider guideProvider) {
    if (guideProvider.error == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        guideProvider.error!,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  /// Lista de guías
  Widget _buildGuideList() {
    return const Expanded(
      child: ClientDispatchListScreen(),
    );
  }
}
