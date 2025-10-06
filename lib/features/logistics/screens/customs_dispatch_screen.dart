import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import '../providers/auth_provider.dart';
import '../providers/transport_cube_provider.dart';
import '../providers/guide_provider.dart';
import '../models/operation_models.dart';

// Models
import '../models/transport_cube_state.dart';
import '../models/cube_type.dart';

// Presentation - constants, helpers & widgets
import '../presentation/constants/visual_states.dart';
import '../presentation/helpers/error_helper.dart';
import '../presentation/widgets/app_drawer.dart';
import '../presentation/widgets/customs_dispatch_scan_box.dart';

// Screens
import 'transport_cube_list_screen.dart';
import 'new_dispatch_screen.dart';

/// Pantalla para despacho en aduana
class CustomsDispatchScreen extends StatefulWidget {
  const CustomsDispatchScreen({super.key});

  @override
  State<CustomsDispatchScreen> createState() => _CustomsDispatchScreenState();
}

class _CustomsDispatchScreenState extends State<CustomsDispatchScreen> {
  @override
  void initState() {
    super.initState();
    developer.log(
      'CustomsDispatchScreen - Initializing',
      name: 'CustomsDispatchScreen',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      developer.log(
        'CustomsDispatchScreen - Starting initial load',
        name: 'CustomsDispatchScreen',
      );

      final provider = context.read<TransportCubeProvider>();

      // Forzar limpieza y recarga
      provider.clearSelection();
      await provider.changeState(VisualStates.created);

      developer.log(
        'CustomsDispatchScreen - Initial load complete - Cubes count: ${provider.cubes.length}',
        name: 'CustomsDispatchScreen',
      );
    });
  }

  Future<void> _createNewCube(List<String> guides) async {
    final provider = context.read<TransportCubeProvider>();
    final authProvider = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final refreshed = await authProvider.ensureFreshToken();
      developer.log(
        'Token refresh before create cube - Refreshed/Valid: $refreshed',
        name: 'CustomsDispatchScreen',
      );

      final response = await provider.createTransportCube(
        guides,
        CubeType.transitToWarehouse,
      );
      if (!mounted) return;

      response.showMessage(context);

      if (response.isSuccessful) {
        await provider.loadCubes(force: true);
      }
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text(''),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransportCubeProvider>();
    final hasSelectedCubes = provider.selectedCubeIds.isNotEmpty;

    developer.log(
      'CustomsDispatchScreen build - hasSelectedCubes: $hasSelectedCubes, selectedIds: ${provider.selectedCubeIds.join(", ")}',
      name: 'CustomsDispatchScreen',
    );

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Despacho en Aduana'),
        actions: [
          if (hasSelectedCubes) ...[
            // Botón de Tránsito
            if (provider.selectedCubes.every(
                  (cubeId) => provider.cubes
                  .firstWhere((c) => c.id == cubeId)
                  .type == CubeType.transitToWarehouse,
            )) ...[
              TextButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final resp = await provider.changeSelectedCubesState(
                    TransportCubeState.sent,
                  );
                  if (!mounted) return;

                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(resp.isSuccessful 
                          ? (resp.message ?? 'Operación exitosa')
                          : (resp.messageDetail ?? 'Error en la operación')),
                      backgroundColor: resp.isSuccessful ? Colors.green : Colors.red,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(8),
                    ),
                  );

                  if (resp.isSuccessful) {
                    await provider.loadCubes(force: true);
                  }
                },
                icon: const Icon(Icons.local_shipping),
                label: Text(
                  'Tránsito (${provider.selectedCubeIds.length})',
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Botón de Despacho
            if (provider.selectedCubes.every((cubeId) {
              final cubeType =
                  provider.cubes.firstWhere((c) => c.id == cubeId).type;
              return cubeType == CubeType.toDispatchToSubcourier ||
                  cubeType == CubeType.toDispatchToClient;
            })) ...[
              TextButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final resp = await provider.dispatchSelectedCubesToClient();
                  if (!mounted) return;

                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(resp.isSuccessful 
                          ? (resp.message ?? 'Despacho completado exitosamente')
                          : (resp.messageDetail ?? 'Error en el despacho')),
                      backgroundColor: resp.isSuccessful ? Colors.green : Colors.red,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(8),
                    ),
                  );
                },
                icon: const Icon(Icons.home_outlined),
                label: Text(
                  'Despacho (${provider.selectedCubeIds.length})',
                ),
              ),
            ],
          ],
        ],
      ),
      body: const TransportCubeListScreen(
        title: 'Despacho en Aduana',
        initialState: VisualStates.created,
        showHistoric: false,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              heroTag: 'btn1',
              onPressed: () => _showCustomsDispatchDialog(),
              icon: const Icon(Icons.add_box),
              label: const Text('Nuevo Cubo'),
            ),
            const SizedBox(height: 8),
            FloatingActionButton.extended(
              heroTag: 'btn2',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NewDispatchScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.local_shipping),
              label: const Text('Nuevo Despacho'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmCloseDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (confirmCtx) => AlertDialog(
        title: const Text('¿Cerrar ventana?'),
        content: const Text(
          '¿Está seguro que desea cerrar esta ventana? Se perderán las guías escaneadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmCtx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(confirmCtx, true),
            child: const Text('Sí, cerrar'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _showCustomsDispatchDialog() async {
    final parentContext = context;

    await showDialog<void>(
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Crear Nuevo Cubo'),
            IconButton(
              tooltip: 'Cerrar',
              onPressed: () async {
                if (await _confirmCloseDialog(dialogCtx)) {
                  if (!dialogCtx.mounted) return;
                  Navigator.pop(dialogCtx);
                }
              },
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(parentContext).size.width * 0.8,
          child: CustomsDispatchScanBox(
            onComplete: (guides, createCube) async {
              Navigator.pop(dialogCtx);

              if (createCube) {
                _createNewCube(guides);
              } else {
                final guideProvider = parentContext.read<GuideProvider>();

                final request = UpdateGuideStatusRequest(
                  guides: guides,
                  newStatus: TrackingStateType.dispatchedFromCustoms,
                );

                final resp = await guideProvider.updateGuideStatus(request);
                if (!mounted) return;

                resp.showMessage(context);
              }
            },
          ),
        ),
      ),
    );
  }
}
