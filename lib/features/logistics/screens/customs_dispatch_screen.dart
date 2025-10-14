import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import '../providers/transport_cube_provider.dart';


// Models
import '../models/transport_cube_state.dart';
import '../models/cube_type.dart';

// Presentation - constants, helpers & widgets
import '../presentation/constants/visual_states.dart';
import '../presentation/widgets/app_drawer.dart';

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

                  final message = resp.isSuccessful 
                      ? (resp.message ?? 'Operación exitosa')
                      : (resp.messageDetail ?? 'Error en la operación');
                  
                  messenger.showSnackBar(
                    SnackBar(
                      content: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Row(
                          children: [
                            Icon(
                              resp.isSuccessful ? Icons.check_circle : Icons.error,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                message,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      backgroundColor: resp.isSuccessful 
                          ? const Color(0xFF4CAF50) 
                          : const Color(0xFFE53E3E),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: resp.isSuccessful ? 4 : 5),
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

                  final message = resp.isSuccessful 
                      ? (resp.message ?? 'Despacho completado exitosamente')
                      : (resp.messageDetail ?? 'Error en el despacho');
                  
                  messenger.showSnackBar(
                    SnackBar(
                      content: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Row(
                          children: [
                            Icon(
                              resp.isSuccessful ? Icons.check_circle : Icons.error,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                message,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      backgroundColor: resp.isSuccessful 
                          ? const Color(0xFF4CAF50) 
                          : const Color(0xFFE53E3E),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: resp.isSuccessful ? 4 : 5),
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
              onPressed: () {
                Navigator.pushNamed(context, '/transport-cube/new');
              },
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
}
