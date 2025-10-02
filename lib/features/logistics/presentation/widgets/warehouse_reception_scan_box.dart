import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/operation_models.dart';
import '../../providers/guide_provider.dart';
import '../controllers/scan_controller.dart';
import '../../services/app_sounds.dart';

/// Widget para escaneo de guías en recepción en bodega
class WarehouseReceptionScanBox extends StatefulWidget {
  final Function(List<String>) onComplete;

  const WarehouseReceptionScanBox({super.key, required this.onComplete});

  @override
  State<WarehouseReceptionScanBox> createState() =>
      _WarehouseReceptionScanBoxState();
}

class _WarehouseReceptionScanBoxState extends State<WarehouseReceptionScanBox> {
  // Controllers y focus
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScanController _scanController = ScanController();

  // Estado interno
  final Set<String> _scannedGuides = {};

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

  /// Maneja la entrada de una guía
  Future<void> _handleGuideInput(String? guide) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (guide == null || guide.trim().isEmpty) return;

    final cleanGuide = guide.trim();

    await _scanController.processScan(() async {
      try {
        final response = await context.read<GuideProvider>().searchGuide(
          cleanGuide,
          status: TrackingStateType.transitToWarehouse,
        );

        if (!response.isSuccessful || response.content == null) {
          HapticFeedback.heavyImpact();
          await AppSounds.error();
          if (!mounted) return;

          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(response.messageDetail ?? ''),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          if (_scannedGuides.contains(cleanGuide)) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(response.messageDetail ?? ''),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            setState(() => _scannedGuides.add(cleanGuide));
            try {
              await AppSounds.success().timeout(const Duration(seconds: 2));
            } catch (_) {}
            if (!mounted) return;
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(response.messageDetail ?? ''),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (_) {
        if (!mounted) return;
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        await AppSounds.error();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Error al procesar la guía'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      } finally {
        if (mounted) {
          _controller.clear();
          Future.microtask(() {
            if (!_focusNode.hasFocus) _focusNode.requestFocus();
          });
        }
      }
    });
  }

  /// Completa el proceso de recepción
  Future<void> _complete() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (_scannedGuides.isEmpty) return;

    final provider = context.read<GuideProvider>();
    final guides = _scannedGuides.toList();

    final request = UpdateGuideStatusRequest(
      guides: guides,
      newStatus: TrackingStateType.receivedInLocalWarehouse,
    );

    debugPrint('[DEBUG] Enviando request con newStatus: "${TrackingStateType.receivedInLocalWarehouse}"');
    debugPrint('[DEBUG] Guides: ${guides.join(", ")}');

    final response = await provider.updateGuideStatus(request);
    if (!mounted) return;

    debugPrint('[DEBUG] Respuesta backend: ${response.isSuccessful}, ${response.message}, ${response.messageDetail}');

    if (response.isSuccessful) {
      await Future.delayed(const Duration(milliseconds: 1000));

      bool anyChanged = false;
        final verifyProvider = provider;

      for (final guide in guides) {
        final verifyResponse = await verifyProvider.searchGuide(
          guide,
          status: TrackingStateType.receivedInLocalWarehouse,
        );

        if (verifyResponse.isSuccessful && verifyResponse.content != null) {
          anyChanged = true;
          debugPrint('[DEBUG] Guía $guide confirmada en estado ReceivedInLocalWarehouse');
          break;
        }
      }

      if (anyChanged) {
        widget.onComplete(guides);
        setState(() => _scannedGuides.clear());

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(response.messageDetail ?? ''),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        debugPrint('[DEBUG] Backend dijo exitoso pero las guías no cambiaron de estado');
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(response.messageDetail ?? ''),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(response.messageDetail ?? ''),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }

    Future.microtask(() {
      if (!_focusNode.hasFocus) _focusNode.requestFocus();
    });
  }

  /// Elimina una guía de la lista
  void _removeGuide(String guide) => setState(() => _scannedGuides.remove(guide));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Mantener foco en el campo
    Future.microtask(() {
      if (!_focusNode.hasFocus) _focusNode.requestFocus();
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Campo de entrada
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 128),
            ),
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
              if (value.endsWith('\\n')) {
                _handleGuideInput(value.replaceAll('\\n', ''));
              }
            },
            onSubmitted: _handleGuideInput,
          ),
        ),

        if (_scannedGuides.isNotEmpty) ...[
          const SizedBox(height: 16),

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
              separatorBuilder: (_, __) => const Divider(),
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
