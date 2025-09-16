import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:provider/provider.dart';
import '../../../core/models/api_response.dart';
import '../providers/transport_cube_provider.dart';
import '../providers/guide_provider.dart';
import '../providers/auth_provider.dart';
import '../models/transport_cube_state.dart';
import '../models/operation_models.dart';
import '../presentation/constants/visual_states.dart';
import '../presentation/widgets/customs_dispatch_scan_box.dart';
import '../presentation/helpers/error_helper.dart';
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

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          response.messageDetail ?? response.message ?? 
          (response.isSuccessful ? 'Cubo creado correctamente' : 'Error al crear cubo')
        ),
        backgroundColor: response.isSuccessful ? Colors.green : Colors.red,
      ));

      // Si fue exitoso, recargar la lista de cubos (forzado)
      if (response.isSuccessful) {
        await provider.loadCubes(force: true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error inesperado: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  void initState() {
    super.initState();
    developer.log(
        'CustomsDispatchScreen - Initializing', name: 'CustomsDispatchScreen');
    // Usar addPostFrameCallback para evitar setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      developer.log('CustomsDispatchScreen - Starting initial load',
          name: 'CustomsDispatchScreen');
      final provider = context.read<TransportCubeProvider>();
      // Forzar limpieza y recarga
      provider.clearSelection();
      await provider.changeState(VisualStates.created);
      developer.log(
        'CustomsDispatchScreen - Initial load complete - Cubes count: ${provider
            .cubes.length}',
        name: 'CustomsDispatchScreen',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransportCubeProvider>();
    final hasSelectedCubes = provider.selectedCubeIds.isNotEmpty;

    developer.log(
      'CustomsDispatchScreen build - hasSelectedCubes: $hasSelectedCubes, selectedIds: ${provider
          .selectedCubeIds.join(", ")}',
      name: 'CustomsDispatchScreen',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Despacho en Aduana'),
        actions: [
          if (hasSelectedCubes)
            TextButton.icon(
              onPressed: () => _createNewCube([]),
              // Hook opcional si se quiere desde aquí
              icon: const Icon(Icons.local_shipping),
              label: Text(
                  'Enviar a Tránsito ${provider.selectedCubeIds.length} cubos'),
            ),
        ],
      ),
      body: TransportCubeListScreen(
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
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Nuevo Cubo'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: CustomsDispatchScanBox(
            onComplete: (guides) {
              Navigator.pop(context);
              _createNewCube(guides);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}