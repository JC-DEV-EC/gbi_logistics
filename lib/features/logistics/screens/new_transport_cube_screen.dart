import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transport_cube_provider.dart';
import '../models/transport_cube_state.dart';
import '../presentation/helpers/error_helper.dart';

class NewTransportCubeScreen extends StatefulWidget {
  const NewTransportCubeScreen({super.key});

  @override
  State<NewTransportCubeScreen> createState() => _NewTransportCubeScreenState();
}

class _NewTransportCubeScreenState extends State<NewTransportCubeScreen> {
  final TextEditingController _guideController = TextEditingController();
  final List<String> _guides = [];
  bool _isProcessing = false;

  @override
  void dispose() {
    _guideController.dispose();
    super.dispose();
  }

  void _addGuide(String? guide) {
    if (guide == null || guide.isEmpty) return;

    final cleanGuide = guide.trim();
    if (cleanGuide.isEmpty) return;

    setState(() {
      if (!_guides.contains(cleanGuide)) {
        _guides.add(cleanGuide);
      }
      _guideController.clear();
    });
    if (guide == null || guide.isEmpty) return;

  }

  void _removeGuide(String guide) {
    setState(() {
      _guides.remove(guide);
    });
  }

  Future<void> _createCube() async {
    if (_guides.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Agregue al menos una guía'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final apiResp = await context.read<TransportCubeProvider>().createTransportCube(_guides);

      if (!mounted) return;

      if (apiResp.isSuccessful) {
        final provider = context.read<TransportCubeProvider>();
        // Asegurar que estamos en el estado correcto después de crear el cubo
        await provider.changeState(TransportCubeState.CREATED);
        
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiResp.messageDetail ?? apiResp.message ?? '✅ Cubo creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ErrorHelper.showErrorSnackBar(context, apiResp.messageDetail ?? apiResp.message ?? 'Error al crear cubo');
      }
    } catch (e) {
      ErrorHelper.showErrorSnackBar(context, e);
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
        title: const Text('Nuevo Cubo'),
      ),
      body: Column(
        children: [
          // Entrada de guías
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _guideController,
              decoration: InputDecoration(
                labelText: 'Guía',
                hintText: 'Escanee o ingrese el código de la guía',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _addGuide(_guideController.text),
                ),
              ),
              onSubmitted: _addGuide,
              enabled: !_isProcessing,
            ),
          ),

          // Lista de guías agregadas
          Expanded(
            child: _guides.isEmpty
                ? Center(
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
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _guides.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final guide = _guides[index];
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
                  onPressed: _isProcessing || _guides.isEmpty ? null : _createCube,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(),
                        )
                      : const Icon(Icons.add),
                  label: const Text('Crear Cubo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
