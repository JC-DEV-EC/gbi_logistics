import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/operation_models.dart';
import '../../providers/guide_provider.dart';
import '../controllers/scan_controller.dart';
/*import '../../services/app_sounds.dart';*/
import '../../../../core/services/app_logger.dart';
import '../helpers/error_helper.dart';

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
      ],
    );
  }

  Future<void> _handleGuideInput(String? guide) async {
    if (guide == null || guide.trim().isEmpty) return;

    final cleanGuide = guide.trim();

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
          /*await AppSounds.error();*/
          MessageHelper.showIconSnackBar(
            context,
            message: response.messageDetail ?? 'Error al actualizar guía',
            isSuccess: false,
          );
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
          message: response.message ?? 'Guía recibida correctamente',
          isSuccess: true,
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