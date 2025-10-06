import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transport_cube_state.dart';
import '../providers/auth_provider.dart';
import '../providers/transport_cube_provider.dart';
import '../models/cube_type.dart';
import '../presentation/helpers/error_helper.dart';
import '../presentation/widgets/subcourier_client_selector.dart';
import '../presentation/widgets/guide_validation_scan_box.dart';

/// Pantalla para crear nuevo despacho directo a cliente
class NewDispatchScreen extends StatefulWidget {
  const NewDispatchScreen({super.key});

  @override
  State<NewDispatchScreen> createState() => _NewDispatchScreenState();
}

class _NewDispatchScreenState extends State<NewDispatchScreen> {
  final List<String> _validatedGuides = [];
  int? _selectedSubcourierId;
  String? _selectedClientId;
  bool _isProcessing = false;
  bool _requiresClient = false;
  bool _selectionsLocked = false;

  void _onGuideValidated(String guide) {
    if (!_validatedGuides.contains(guide)) {
      setState(() {
        _validatedGuides.insert(0, guide);
        // Bloquear selecciones al validar la primera guía
        _selectionsLocked = true;
      });
    }
  }

  void _removeGuide(String guide) {
    setState(() {
      _validatedGuides.remove(guide);
      // Si ya no hay guías, desbloquear selecciones
      if (_validatedGuides.isEmpty) {
        _selectionsLocked = false;
      }
    });
  }

  Future<void> _createDispatchCube() async {
    if (_validatedGuides.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agregue al menos una guía para crear el despacho'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Refrescar token primero
      final authProvider = context.read<AuthProvider>();
      await authProvider.ensureFreshToken();

      if (!mounted) return;

      final provider = context.read<TransportCubeProvider>();

      // Crear el cubo y establecerlo directamente en estado Downloaded
      final response = await provider.createTransportCube(
        _validatedGuides,
        CubeType.toDispatchToClient,
      );

      if (!mounted) return;

      if (response.isSuccessful) {
        final cubeId = response.content?.content?.id;
        if (cubeId != null) {
          await provider.changeSelectedCubesState(TransportCubeState.downloaded);
          await provider.loadCubes(force: true);
        }

        if (!mounted) return;
        setState(() {
          _validatedGuides.clear();
          _selectionsLocked = false;
        });
        Navigator.pop(context);
      }

      // Mostrar mensaje del backend (éxito o error)
      response.showMessage(context);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Despacho'),
      ),
      body: Column(
        children: [
          // Selectores de subcourier y cliente
          Padding(
            padding: const EdgeInsets.all(16),
            child: SubcourierClientSelector(
              isLocked: _selectionsLocked,
              onSubcourierSelected: (id) => setState(() => _selectedSubcourierId = id),
              onClientSelected: (id) => setState(() => _selectedClientId = id),
              onRequiresClientChanged: (requires) => setState(() => _requiresClient = requires),
            ),
          ),

          // Scanner de guías con validación
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GuideValidationScanBox(
              selectedSubcourierId: _selectedSubcourierId,
              selectedClientId: _selectedClientId,
              onGuideValidated: _onGuideValidated,
              requiresClient: _requiresClient,
            ),
          ),

          // Lista de guías validadas
          Expanded(
            child: _validatedGuides.isEmpty
                ? SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay guías agregadas',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Escanee o ingrese los códigos de las guías',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _validatedGuides.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final guide = _validatedGuides[index];
                return ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: Text(guide),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _isProcessing ? null : () => _removeGuide(guide),
                    color: Colors.red,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isProcessing || _validatedGuides.isEmpty
                      ? null
                      : _createDispatchCube,
                  icon: _isProcessing
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(),
                  )
                      : const Icon(Icons.add),
                  label: const Text('Crear Despacho'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}