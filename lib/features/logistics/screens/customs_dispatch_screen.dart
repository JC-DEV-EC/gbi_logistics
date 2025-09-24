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

// Presentation - constants, helpers & widgets
import '../presentation/constants/visual_states.dart';
import '../presentation/widgets/app_drawer.dart';
import '../presentation/widgets/customs_dispatch_scan_box.dart';

// Screens
import 'transport_cube_list_screen.dart';

/// Pantalla para despacho en aduana
class CustomsDispatchScreen extends StatefulWidget {
  const CustomsDispatchScreen({super.key});

  @override
  State<CustomsDispatchScreen> createState() => _CustomsDispatchScreenState();
}

class _CustomsDispatchScreenState extends State<CustomsDispatchScreen> {
  Future<void> _createNewCube(List<String> guides) async {
    final provider = context.read<TransportCubeProvider>();

    try {
      // Refrescar token primero
      final refreshed = await context.read<AuthProvider>().ensureFreshToken();
      developer.log(
        'Token refresh before create cube - Refreshed/Valid: $refreshed',
        name: 'CustomsDispatchScreen',
      );

      // Crear el cubo con las guías (el backend maneja los estados)
      final response = await provider.createTransportCube(guides);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.messageDetail ??
                response.message ??
                (response.isSuccessful
                    ? 'Cubo creado correctamente'
                    : 'Error al crear cubo'),
          ),
          backgroundColor: response.isSuccessful ? Colors.green : Colors.red,
        ),
      );

      // Si fue exitoso, recargar la lista de cubos (forzado)
      if (response.isSuccessful) {
        await provider.loadCubes(force: true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    developer.log(
      'CustomsDispatchScreen - Initializing',
      name: 'CustomsDispatchScreen',
    );

    // Usar addPostFrameCallback para evitar setState durante build
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
          if (hasSelectedCubes)
            TextButton.icon(
              onPressed: () async {
                // Enviar cubos seleccionados a estado Tránsito en Bodega (Sent)
                final resp = await provider.changeSelectedCubesState(
                  TransportCubeState.SENT,
                );
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      resp.messageDetail ??
                          resp.message ??
                          'Operación completada',
                    ),
                    backgroundColor:
                    resp.isSuccessful ? Colors.green : Colors.red,
                  ),
                );

                if (resp.isSuccessful) {
                  // Recargar listado actualizado y limpiar selección
                  await provider.loadCubes(force: true);
                }
              },
              icon: const Icon(Icons.local_shipping),
              label: Text(
                'Enviar a Tránsito ${provider.selectedCubeIds.length} cubos',
              ),
            ),
        ],
      ),
      body: const TransportCubeListScreen(
        title: 'Despacho en Aduana',
        initialState: VisualStates.created,
        showHistoric: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCustomsDispatchDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Cubo'),
      ),
    );
  }

  Future<void> _showCustomsDispatchDialog() async {
    // Guardar el context padre (de la pantalla) para usarlo después del pop
    final parentContext = context;

    await showDialog<void>(
      context: parentContext,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Crear Nuevo Cubo'),
        content: SizedBox(
          width: MediaQuery.of(parentContext).size.width * 0.8,
          child: CustomsDispatchScanBox(
            onComplete: (guides, createCube) async {
              // Cerrar el diálogo usando su propio context
              Navigator.pop(dialogCtx);

              if (createCube) {
                // Lógica de creación de cubo (mantiene su comportamiento original)
                _createNewCube(guides);
              } else {
                // Solo actualizar estado de las guías a DispatchedFromCustoms
                // sin ninguna relación con cubos
                final guideProvider = parentContext.read<GuideProvider>();
                final request = UpdateGuideStatusRequest(
                  guides: guides,
                  newStatus: TrackingStateType.dispatchedFromCustoms,
                );
                final resp = await guideProvider.updateGuideStatus(request);

                // Siempre mostrar el messageDetail del servidor si existe
                final serverMessage = resp.messageDetail ?? resp.message ?? '';
                final bool hasFailedGuides = !resp.isSuccessful || serverMessage.isNotEmpty;

                // Determinar color basado en la respuesta
                final Color feedbackColor = !resp.isSuccessful ? Colors.red : Colors.green;

                // Construir mensaje respetando el messageDetail del servidor
                String feedbackMessage = serverMessage;
                if (feedbackMessage.isEmpty) {
                    feedbackMessage = resp.isSuccessful 
                        ? 'Se actualizaron ${guides.length} guías correctamente'
                        : 'Error al actualizar las guías';
                }

                // Mostrar feedback usando el context padre (no el del diálogo)
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text(feedbackMessage),
                    backgroundColor: feedbackColor,
                    // Dar más tiempo si hay mensaje detallado del servidor
                    duration: serverMessage.isNotEmpty 
                        ? const Duration(seconds: 10)
                        : const Duration(seconds: 4),
                  ),
                );
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}
