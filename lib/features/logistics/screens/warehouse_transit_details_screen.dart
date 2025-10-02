import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transport_cube_provider.dart';
import '../models/transport_cube_details.dart';
import '../presentation/constants/visual_states.dart';
import '../providers/guide_provider.dart';
import '../models/operation_models.dart';
import '../presentation/widgets/warehouse_reception_scan_box.dart';
import 'transport_cube_details_base_screen.dart';

/// Pantalla de detalles para cubo en tránsito a bodega
class WarehouseTransitDetailsScreen extends TransportCubeDetailsBaseScreen {
  const WarehouseTransitDetailsScreen({
    super.key,
    required super.cubeId,
  });

  @override
  State<WarehouseTransitDetailsScreen> createState() => _WarehouseTransitDetailsScreenState();
}

class _WarehouseTransitDetailsScreenState extends TransportCubeDetailsBaseScreenState<WarehouseTransitDetailsScreen> {
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
      onPressed: () => _confirmStartDownload(context),
      icon: const Icon(Icons.move_to_inbox),
      label: Text(VisualStates.getActionButtonLabel(VisualStates.sent)),
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
                  'Recepción de guías para bodega',
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
            WarehouseReceptionScanBox(
              onComplete: (scanned) async {
                if (scanned.isEmpty) return;

                // Cambiar estado de guías a ReceivedInLocalWarehouse
                final request = UpdateGuideStatusRequest(
                  guides: scanned,
                  newStatus: TrackingStateType.receivedInLocalWarehouse,
                );

                final guideProvider = context.read<GuideProvider>();
                final messenger = ScaffoldMessenger.of(context);
                final response = await guideProvider.updateGuideStatus(request);
                
                if (!mounted) return;

                // Mostrar mensaje del backend (éxito o error)
                messenger.showSnackBar(SnackBar(
                  content: Text(response.messageDetail ?? ''),
                  backgroundColor: response.isSuccessful ? Colors.green : Colors.red,
                ));

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


  Future<void> _confirmStartDownload(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final transportProvider = context.read<TransportCubeProvider>();
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar recepción en bodega'),
        content: const Text(
          '¿Está seguro que desea iniciar la recepción de este cubo en bodega?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Iniciar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final resp = await transportProvider.changeSelectedCubesState(
        VisualStates.downloading,
      );

      if (resp.isSuccessful && mounted) {
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(resp.messageDetail ?? ''),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
