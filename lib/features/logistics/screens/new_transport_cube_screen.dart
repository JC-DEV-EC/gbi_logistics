import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/transport_cube_provider.dart';
import '../providers/guide_provider.dart';
import '../presentation/widgets/customs_dispatch_scan_box.dart';
import '../models/operation_models.dart';
import '../models/cube_type.dart';
import '../presentation/helpers/error_helper.dart';

/// Pantalla para crear un nuevo cubo de transporte
class NewTransportCubeScreen extends StatefulWidget {
  const NewTransportCubeScreen({super.key});

  @override
  State<NewTransportCubeScreen> createState() => _NewTransportCubeScreenState();
}

class _NewTransportCubeScreenState extends State<NewTransportCubeScreen> {
  Future<bool> _confirmClose() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (confirmCtx) => AlertDialog(
        title: const Text('¿Cerrar ventana?'),
        content: const Text(
          '¿Está seguro que desea cerrar esta ventana? Se perderán las guías escaneadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmCtx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(confirmCtx, true),
            child: const Text('Sí, cerrar'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _createNewCube(List<String> guides) async {
    final provider = context.read<TransportCubeProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final response = await provider.createTransportCube(
        guides,
        CubeType.transitToWarehouse,
      );

      if (!mounted) return;

      if (!mounted) return;

      if (response.isSuccessful) {
        await provider.loadCubes(force: true);
        if (!mounted) return;
        Navigator.pop(context);
      }

      final message = response.isSuccessful
          ? (response.message ?? 'Operación exitosa')
          : (response.messageDetail ?? 'Error en la operación');

      MessageHelper.showIconSnackBar(
        context,
        message: message,
        isSuccess: response.isSuccessful,
      );
    } catch (_) {
      if (!mounted) return;
      MessageHelper.showIconSnackBar(
        context,
        message: 'Error al crear el cubo',
        isSuccess: false,
      );

      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(
                Icons.error,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Error al crear el cubo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFE53E3E),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nuevo Cubo'),
        leading: IconButton(
          tooltip: 'Cerrar',
          icon: const Icon(Icons.close),
          onPressed: () async {
            if (await _confirmClose()) {
              if (!mounted) return;
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: CustomsDispatchScanBox(
          onComplete: (guides, createCube) async {
            if (createCube) {
              await _createNewCube(guides);
            } else {
              final guideProvider = context.read<GuideProvider>();

              final request = UpdateGuideStatusRequest(
                guides: guides,
                newStatus: TrackingStateType.dispatchedFromCustoms,
              );

              final resp = await guideProvider.updateGuideStatus(request);
              if (!mounted) return;

              resp.showMessage(context);
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }
}
