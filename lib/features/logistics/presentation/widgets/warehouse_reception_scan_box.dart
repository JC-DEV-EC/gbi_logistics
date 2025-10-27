import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/operation_models.dart';
import '../../providers/guide_provider.dart';
import '../controllers/scan_controller.dart';
/*import '../../services/app_sounds.dart';*/
import '../../../../core/services/app_logger.dart';
import '../helpers/error_helper.dart';
import '../../services/native_sound_service.dart';

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
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScanController _scanController = ScanController();
  final Set<String> _scannedGuides = {};
  bool _isBlocked = false; // Bloquea el scanner cuando hay error

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Future.microtask(() {
      if (!_focusNode.hasFocus) _focusNode.requestFocus();
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
            enabled: !_isBlocked, // Deshabilitar cuando está bloqueado
            decoration: InputDecoration(
              hintText: _isBlocked
                  ? 'Presione Continuar en el diálogo de error'
                  : 'Escanee o ingrese el código de la guía',
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
              suffixIcon: Icon(
                Icons.qr_code_scanner,
                color: _isBlocked
                    ? theme.colorScheme.outline
                    : theme.colorScheme.primary.withValues(alpha: 128),
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
      ],
    );
  }

  Future<void> _handleGuideInput(String? guide) async {
    if (guide == null || guide.trim().isEmpty) return;

    final cleanGuide = guide.trim();
    
    // No procesar si está bloqueado (evita que el scanner físico envíe datos)
    if (_isBlocked) return;

    await _scanController.processScan(() async {
      try {
        final guideProvider = context.read<GuideProvider>();

        // Actualizar estado directamente
        final updateRequest = UpdateGuideStatusRequest(
          guides: [cleanGuide],
          newStatus: TrackingStateType.receivedInLocalWarehouse,
        );

        final response = await guideProvider.updateGuideStatus(updateRequest);

        if (!response.isSuccessful) {
          // Sonido de error nativo del sistema
          NativeSoundService.playErrorSound();
          
          // Bloquear el scanner
          setState(() {
            _isBlocked = true;
          });
          
          // Mostrar diálogo bloqueante de error
          await MessageHelper.showBlockingErrorDialog(
            context,
            response.messageDetail ?? 'Error al procesar la guía',
          );
          
          // Desbloquear el scanner después de cerrar el diálogo
          if (mounted) {
            setState(() {
              _isBlocked = false;
            });
          }
          return;
        }

        // Actualización exitosa
        setState(() => _scannedGuides.add(cleanGuide));
        /*await AppSounds.success();*/

        AppLogger.log(
          'Reception scan success messageDetail: ${response.messageDetail ?? ''}',
          source: 'WarehouseReception',
        );

        MessageHelper.showIconSnackBar(
          context,
          message: response.message ?? '',
          isSuccess: true,
          successDuration: const Duration(milliseconds: 500),
        );

        // Notificar cambio
        widget.onComplete([cleanGuide]);
      } catch (e) {
        if (!mounted) return;
        /*await AppSounds.error();*/
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
}