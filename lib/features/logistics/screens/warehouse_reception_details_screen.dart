import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transport_cube_provider.dart';
import '../presentation/constants/visual_states.dart';
import '../models/transport_cube_details.dart';
import '../models/operation_models.dart';
import '../providers/guide_provider.dart';
import '../presentation/widgets/warehouse_reception_scan_box.dart';
import '../presentation/helpers/error_helper.dart';
import 'transport_cube_details_base_screen.dart';

/// Pantalla de detalles para cubo en recepción en bodega
class WarehouseReceptionDetailsScreen extends TransportCubeDetailsBaseScreen {
  const WarehouseReceptionDetailsScreen({
    super.key,
    required super.cubeId,
  });

  @override
  State<WarehouseReceptionDetailsScreen> createState() => _WarehouseReceptionDetailsScreenState();
}

class _WarehouseReceptionDetailsScreenState extends TransportCubeDetailsBaseScreenState<WarehouseReceptionDetailsScreen> {
  @override
  List<Widget> buildAppBarActions() {
    return [
      IconButton(
        icon: const Icon(Icons.history),
        onPressed: _showHistory,
      ),
    ];
  }

  @override
  Widget buildActionButton(TransportCubeDetails details) {
    return FloatingActionButton.extended(
      onPressed: () => _confirmFinishDownload(context),
      icon: const Icon(Icons.done_all),
      label: Text(VisualStates.getActionButtonLabel(VisualStates.downloading)),
    );
  }

  @override
  Widget? buildAdditionalControls(TransportCubeDetails details) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.move_to_inbox),
                const SizedBox(width: 8),
                Text(
                  'Recepción en Bodega',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Guías en el cubo: ${details.guides.length}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            // Caja de escaneo inline
            WarehouseReceptionScanBox(
              onComplete: (scanned) async {
                if (scanned.isEmpty) return;

                // Cambiar estado de guías a ReceivedInLocalWarehouse
                final request = UpdateGuideStatusRequest(
                  guides: scanned,
                  newStatus: TrackingStateType.receivedInLocalWarehouse,
                );

                final guideProvider = context.read<GuideProvider>();
                final response = await guideProvider.updateGuideStatus(request);
                
                if (!mounted) return;

                // Mostrar mensaje del backend (éxito o error)
                response.showMessage(context);

                // Si fue exitoso, recargar detalles
                if (response.isSuccessful) {
                  await refreshDetails(withDelay: true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showHistory() async {
    final transportProvider = context.read<TransportCubeProvider>();
    final history = await transportProvider.getCubeHistory(widget.cubeId);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Historial - Cubo #${widget.cubeId}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: history.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, index) {
              final item = history[index];
              return ListTile(
                title: Text(item),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }


  Future<void> _confirmFinishDownload(BuildContext context) async {
    final transportProvider = context.read<TransportCubeProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar fin de descarga'),
        content: const Text(
          '¿Está seguro que desea finalizar la descarga de este cubo?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final resp = await transportProvider.changeSelectedCubesState(
                VisualStates.downloaded,
      );

      if (resp.isSuccessful && mounted) {
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(resp.message ?? ''),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(8),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(8),
          ),
        );
      }
    }
  }
}
