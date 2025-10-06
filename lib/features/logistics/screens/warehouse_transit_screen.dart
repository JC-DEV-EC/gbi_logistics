import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import '../providers/auth_provider.dart';
import '../providers/guide_provider.dart';
import '../providers/transport_cube_provider.dart';

// Models
import '../models/operation_models.dart';
import '../models/transport_cube_state.dart';

// Presentation
import '../presentation/constants/visual_states.dart';
import '../presentation/widgets/app_drawer.dart';

// Screens
import 'transport_cube_list_screen.dart';

/// Pantalla para tránsito a bodega
class WarehouseTransitScreen extends StatelessWidget {
  const WarehouseTransitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransportCubeProvider>();
    final hasSelectedCubes = provider.selectedCubeIds.isNotEmpty;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Tránsito a Bodega'),
        actions: hasSelectedCubes
            ? [
          TextButton.icon(
            onPressed: () {
              developer.log(
                'Enviar a Recepción tapped - Selected cubes: ${provider.selectedCubeIds.join(", ")}',
                name: 'WarehouseTransitScreen',
              );
              _showSendToReceptionDialog(context);
            },
            icon: const Icon(Icons.warehouse_outlined),
            label: Text(
              'Enviar a Recepción ${provider.selectedCubeIds.length} cubos',
            ),
          ),
        ]
            : null,
      ),
      body: const TransportCubeListScreen(
        title: 'Tránsito a Bodega',
        initialState: VisualStates.sent,
        showHistoric: false,
      ),
    );
  }

  Future<void> _showSendToReceptionDialog(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final provider = context.read<TransportCubeProvider>();
    final auth = context.read<AuthProvider>();
    final transportProvider = context.read<TransportCubeProvider>();
    final guideProvider = context.read<GuideProvider>();
    final cubeCount = provider.selectedCubeIds.length;

    developer.log(
      'Sending cubes to reception dialog - Selected cubes: ${provider.selectedCubeIds.join(', ')}',
      name: 'WarehouseTransitScreen',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar envío'),
        content: Text(
          '¿Está seguro que desea enviar $cubeCount '
              '${cubeCount == 1 ? 'cubo' : 'cubos'} a recepción?\n\n'
              'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      developer.log(
        'Starting transit flow: update guides to TransitToWarehouse then set cubes to Sent',
        name: 'WarehouseTransitScreen',
      );

      // Refrescar token preventivamente
      final refreshed = await auth.ensureFreshToken();
      developer.log(
        'Token refresh before change state - Refreshed/Valid: $refreshed',
        name: 'WarehouseTransitScreen',
      );

      // 1) Recolectar guías de los cubos seleccionados
      final guideCodes = <String>{};
      for (final cubeId in transportProvider.selectedCubeIds) {
        final details = await transportProvider.fetchCubeDetailsRaw(
          cubeId,
          suppressAuthHandling: true,
        );
        guideCodes.addAll(
          details.guides.map((g) => g.packageCode).whereType<String>(),
        );
      }

      developer.log(
        'Collected ${guideCodes.length} guide codes from selected cubes',
        name: 'WarehouseTransitScreen',
      );

      // 2) Actualizar estado de guías a TransitToWarehouse
      if (guideCodes.isNotEmpty) {
        final guidesUpdate = await guideProvider.updateGuideStatus(
          UpdateGuideStatusRequest(
            guides: guideCodes.toList(),
            newStatus: TrackingStateType.transitToWarehouse,  // valor real: 'TransitToWarehouse'
          ),
        );

        if (!guidesUpdate.isSuccessful) {
          if (!context.mounted) return;
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                guidesUpdate.messageDetail ??
                    'Error actualizando guías a Tránsito',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                guidesUpdate.message ??
                    'Guías actualizadas a Tránsito',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(8),
            ),
          );
        }
      }

      // 3) Cambiar estado del cubo a Sent
      final response =
      await transportProvider.changeSelectedCubesState(TransportCubeState.sent);

      developer.log(
        'Cube state changed to Sent - Success: ${response.isSuccessful}',
        name: 'WarehouseTransitScreen',
      );

      if (!context.mounted) return;

      if (response.isSuccessful) {
        transportProvider.clearSelection();
        await transportProvider.loadCubes(); // Recargar lista de cubos

        if (!context.mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              response.message ??
                  '$cubeCount ${cubeCount == 1 ? 'cubo enviado' : 'cubos enviados'} a Tránsito',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(8),
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              response.messageDetail ??
                  'Error al cambiar estado de cubos a Sent',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
