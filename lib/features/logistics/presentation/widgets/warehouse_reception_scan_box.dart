import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/guide_provider.dart';
import '../controllers/scan_controller.dart';

/// Widget para escaneo de guías en recepción en bodega
class WarehouseReceptionScanBox extends StatefulWidget {
  final Function(List<String>) onComplete;

  const WarehouseReceptionScanBox({
    super.key,
    required this.onComplete,
  });

  @override
  State<WarehouseReceptionScanBox> createState() => _WarehouseReceptionScanBoxState();
}

class _WarehouseReceptionScanBoxState extends State<WarehouseReceptionScanBox> {
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

    await _scanController.processScan(() async {
    // Buscar la guía y validar su estado
    final response = await context.read<GuideProvider>().searchGuide(
      cleanGuide,
      status: 'TransitToWarehouse',  // Buscar solo guías en tránsito
    );

    if (response == null) {
      // La guía no existe (o no coincide el estado en el backend)
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ La guía $cleanGuide no se encuentra registrada para recepción'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      // El backend ya filtró por estado TransitToWarehouse: aceptar el escaneo
      setState(() {
        _scannedGuides.add(cleanGuide);
      });
      SystemSound.play(SystemSoundType.click);
    }

    _controller.clear();
    });
  }

  void _complete() {
    if (_scannedGuides.isNotEmpty) {
      widget.onComplete(_scannedGuides.toList());
      setState(() {
        _scannedGuides.clear();
      });
    }
  }

  void _removeGuide(String guide) {
    setState(() {
      _scannedGuides.remove(guide);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Campo de entrada
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5)),
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
                color: theme.colorScheme.primary,
              ),
            ),
            onChanged: (value) {
              if (value.endsWith('\\n')) {
                _handleGuideInput(value.replaceAll('\\n', ''));
              }
            },
            onSubmitted: _handleGuideInput,
          ),
        ),

        if (_scannedGuides.isNotEmpty) ...[
          const SizedBox(height: 16),
          
          // Botón de actualizar estado
          FilledButton.icon(
            onPressed: _complete,
            icon: const Icon(Icons.done),
            label: Text('Recibir ${_scannedGuides.length} guías'),
          ),

          const SizedBox(height: 16),
          
          // Lista de guías escaneadas
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
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
        ],
      ],
    );
  }
}