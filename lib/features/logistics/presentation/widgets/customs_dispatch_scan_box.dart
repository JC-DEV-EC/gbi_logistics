import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/scan_controller.dart';

/// Widget para escaneo de guías en despacho en aduana
class CustomsDispatchScanBox extends StatefulWidget {
  final Function(List<String>, bool createCube) onComplete;

  const CustomsDispatchScanBox({
    super.key,
    required this.onComplete,
  });

  @override
  State<CustomsDispatchScanBox> createState() => _CustomsDispatchScanBoxState();
}

class _CustomsDispatchScanBoxState extends State<CustomsDispatchScanBox> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Set<String> _scannedGuides = {};
  final ScanController _scanController = ScanController();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _handleGuideInput(String? guide) async {
    if (guide == null || guide.isEmpty) return;

    final cleanGuide = guide.trim();
    if (cleanGuide.isEmpty) return;

    // Usar el controlador de escaneo para procesar la guía
    await _scanController.processScan(() async {
      // Agregar la guía escaneada directamente - el backend validará
      setState(() {
        _scannedGuides.add(cleanGuide);
      });
      SystemSound.play(SystemSoundType.click);
      _controller.clear();
      // Mantener el foco
      Future.microtask(() {
        if (!_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
      });
    });
  }

  Future<void> _complete({required bool createCube}) async {
    if (_scannedGuides.isEmpty) return;

    // Procesar todas las guías en un solo request
    final guides = _scannedGuides.toList();

    // Llamar al callback
    widget.onComplete(guides, createCube);

    // Limpiar la lista de guías escaneadas
    setState(() {
      _scannedGuides.clear();
    });

    // Mantener el foco del escáner
    Future.microtask(() {
      if (!_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  void _removeGuide(String guide) {
    setState(() {
      _scannedGuides.remove(guide);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Asegurar que siempre tenemos el foco
    Future.microtask(() {
      if (!_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Campo de entrada
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 128)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Escanee o ingrese el código de la guía',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: InputBorder.none,
                suffixIcon: Icon(
                  Icons.qr_code_scanner,
                  color: theme.colorScheme.primary.withValues(alpha: 128),
                ),
              ),
              onChanged: (value) {
                if (value.endsWith('\n')) {
                  _handleGuideInput(value.replaceAll('\n', ''));
                }
              },
              onSubmitted: _handleGuideInput,
            ),
          ),

          if (_scannedGuides.isNotEmpty) ...[
            const SizedBox(height: 16),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _complete(createCube: true),
                    icon: const Icon(Icons.add_box),
                    label: Text('Crear Cubo (${_scannedGuides.length} guías)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _complete(createCube: false),
                    icon: const Icon(Icons.update),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                    label: Text('Actualizar estado (${_scannedGuides.length})'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Lista de guías escaneadas
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.all(8),
                  shrinkWrap: true,
                  itemCount: _scannedGuides.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final guide = _scannedGuides.elementAt(index);
                    return ListTile(
                      leading: const Icon(Icons.inventory_2_outlined),
                      title: Text(guide),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        color: Colors.red,
                        onPressed: () => _removeGuide(guide),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
