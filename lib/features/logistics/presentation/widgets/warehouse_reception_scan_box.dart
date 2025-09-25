import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../models/operation_models.dart';
import '../../providers/guide_provider.dart';
import '../controllers/scan_controller.dart';
import '../../services/app_sounds.dart';

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
      try {
        // Buscar la guía y validar que esté en estado "Tránsito a Bodega"
        final response = await context.read<GuideProvider>().searchGuide(
          cleanGuide,
          status: TrackingStateType.transitToWarehouse,  // Buscar solo guías en tránsito
        );

        if (!response.isSuccessful || response.content == null) {
          HapticFeedback.heavyImpact();
          await AppSounds.error();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.messageDetail ?? 'Guía no encontrada en estado "Tránsito a Bodega"'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          // La guía existe y está en estado "Tránsito a Bodega", agregarla para cambio de estado
          if (_scannedGuides.contains(cleanGuide)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Guía "$cleanGuide" ya fue escaneada'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            setState(() {
              _scannedGuides.add(cleanGuide);
            });
            // Reproducir sonido sin bloquear la UI y tolerando timeouts/errores
            try { await AppSounds.success().timeout(const Duration(seconds: 2)); } catch (_) {}
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.messageDetail ?? 'Guía validada'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        if (!mounted) return;
        await AppSounds.error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      } finally {
        if (!mounted) return;
        _controller.clear();
        // Mantener el foco
        Future.microtask(() {
          if (!_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
        });
      }
    });
  }

  Future<void> _complete() async {
    if (_scannedGuides.isEmpty) return;

    final provider = context.read<GuideProvider>();
    final guides = _scannedGuides.toList();

    // Actualizar estado de las guías de "Tránsito a Bodega" a "Recibido en Bodega Local"
    final request = UpdateGuideStatusRequest(
      guides: guides,
      newStatus: TrackingStateType.receivedInLocalWarehouse,
    );

    // Log para debugging
    debugPrint('[DEBUG] Enviando request con newStatus: "${TrackingStateType.receivedInLocalWarehouse}"');
    debugPrint('[DEBUG] Guides: ${guides.join(", ")}');
    debugPrint('[DEBUG] HIPÓTESIS: El backend puede estar rechazando el cambio porque las guías están asociadas a un cubo');

    final response = await provider.updateGuideStatus(request);

    if (!mounted) return;

    // Log completo de la respuesta del backend
    debugPrint('[DEBUG] Respuesta completa del backend:');
    debugPrint('[DEBUG] - isSuccessful: ${response.isSuccessful}');
    debugPrint('[DEBUG] - message: ${response.message}');
    debugPrint('[DEBUG] - messageDetail: ${response.messageDetail}');

    // Verificar si la actualización fue exitosa
    if (response.isSuccessful) {
      debugPrint('[DEBUG] Backend respondó exitosamente, verificando cambio real de estado...');
      
      // Esperar un momento para que el backend procese
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Verificar que al menos una guía cambió de estado
      final verifyProvider = context.read<GuideProvider>();
      bool anyChanged = false;
      
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
        // Todas las guías se procesaron correctamente
        widget.onComplete(guides);
        setState(() {
          _scannedGuides.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.messageDetail ?? 'Guías procesadas exitosamente'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        debugPrint('[DEBUG] Backend dijo exitoso pero las guías no cambiaron de estado');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.messageDetail ?? 'Las guías no reflejan el cambio esperado'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } else {
      // Error - mostrar mensaje específico del backend
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.messageDetail ?? 'Error al actualizar las guías'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }

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