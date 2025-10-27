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

  Future<bool> _createNewCube(List<String> guides) async {
    final provider = context.read<TransportCubeProvider>();

    try {
      final response = await provider.createTransportCube(
        guides,
        CubeType.transitToWarehouse,
      );

      if (!mounted) return false;

      if (response.isSuccessful) {
        await provider.loadCubes(force: true);
        if (!mounted) return false;
        
        final message = response.message ?? 'Cubo creado exitosamente';
        MessageHelper.showIconSnackBar(
          context,
          message: message,
          isSuccess: true,
        );
        
        Navigator.pop(context);
        return true; // Éxito
      } else {
        // Mostrar diálogo bloqueante de error
        await MessageHelper.showBlockingErrorDialog(
          context,
          response.messageDetail ?? 'Error al crear el cubo',
        );
        return false; // Error
      }
    } catch (e) {
      if (!mounted) return false;
      // Mostrar diálogo bloqueante de error
      await MessageHelper.showBlockingErrorDialog(
        context,
        'Error al crear el cubo: ${e.toString()}',
      );
      return false; // Error
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
              return await _createNewCube(guides);
            } else {
              final guideProvider = context.read<GuideProvider>();

              final request = UpdateGuideStatusRequest(
                guides: guides,
                newStatus: TrackingStateType.dispatchedFromCustoms,
              );

              final resp = await guideProvider.updateGuideStatus(request);
              if (!mounted) return false;

              if (resp.isSuccessful) {
                resp.showMessage(context);
                Navigator.pop(context);
                return true;
              } else {
                resp.showMessage(context);
                return false;
              }
            }
          },
        ),
      ),
    );
  }
}
