import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/operation_models.dart';
import '../../providers/guide_provider.dart';
import '../controllers/scan_controller.dart';
import '../../services/app_sounds.dart';
import '../../providers/guide_validation_provider.dart';
import '../../../../core/services/app_logger.dart';

/// Widget para escaneo de guías en recepción en bodega
class WarehouseReceptionScanBox extends StatefulWidget {
  final Function(List<String>) onComplete;

  const WarehouseReceptionScanBox({
    super.key,
    required this.onComplete,
  });

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
        // Capturar providers antes de awaits para evitar usar context tras async gaps
        final guideProvider = context.read<GuideProvider>();
        final validationProvider = context.read<GuideValidationProvider>();

        final response = await guideProvider.searchGuide(
          cleanGuide,
          status: TrackingStateType.transitToWarehouse,
        );

        if (!mounted) return;

        final guideExists = response.isSuccessful && response.content != null;

        if (!guideExists || !response.isSuccessful) {
          // No agregar/retener guía si no es reconocida o no tiene el estado correcto
          HapticFeedback.heavyImpact();
          await AppSounds.error();

          // Intentar obtener un messageDetail explícito del backend si vino vacío
          String backendDetail = response.messageDetail ?? '';
          if (backendDetail.isEmpty) {
            final validationResp = await validationProvider
                .validateGuideForCube(guideCode: cleanGuide);
            backendDetail = validationResp.messageDetail ?? '';
          }

          // Log del messageDetail para depuración
          AppLogger.log(
            'Reception scan error messageDetail: $backendDetail',
            source: 'WarehouseReception',
          );

          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(backendDetail),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 6),
            ),
          );

          // Si la guía estaba en la lista, removerla
          if (_scannedGuides.contains(cleanGuide)) {
            setState(() => _scannedGuides.remove(cleanGuide));
          }
        } else if (_scannedGuides.contains(cleanGuide)) {
          // Log del messageDetail para depuración (duplicado)
          AppLogger.log(
            'Reception scan duplicate messageDetail: ${response.messageDetail ?? ''}',
            source: 'WarehouseReception',
          );

          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(response.messageDetail ?? ''),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          // Solo agregar guías validadas por el backend
          setState(() => _scannedGuides.add(cleanGuide));
          await AppSounds.success();

          // Log del messageDetail para depuración (éxito de escaneo)
          AppLogger.log(
            'Reception scan success messageDetail: ${response.messageDetail ?? ''}',
            source: 'WarehouseReception',
          );

          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(response.messageDetail ?? ''),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(8),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        await AppSounds.error();
        // No mostrar mensajes locales, esperar backend
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

    final response = await provider.updateGuideStatus(request);
    if (!mounted) return;

    // Siempre mostrar el messageDetail del backend y no usar vistas adicionales
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(response.messageDetail ?? ''),
        backgroundColor: response.isSuccessful ? Colors.green : Colors.red,
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
      ),
    );

    // Si la operación falló, limpiar las guías escaneadas para desactivar el botón
    if (!response.isSuccessful) {
      setState(() => _scannedGuides.clear());
    } else {
      // En éxito, notificar y limpiar
      widget.onComplete(guides);
      setState(() => _scannedGuides.clear());
    }

    Future.microtask(() {
      if (!_focusNode.hasFocus) _focusNode.requestFocus();
    });
  }

  /// Elimina una guía de la lista
  void _removeGuide(String guide) =>
      setState(() => _scannedGuides.remove(guide));

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
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
