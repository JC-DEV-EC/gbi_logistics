import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transport_cube_provider.dart';
import '../presentation/constants/visual_states.dart';
import '../models/guide_transport_cube_state.dart';
import '../models/transport_cube_details.dart';
import '../models/guide_transport_cube_info.dart';
import '../presentation/helpers/error_helper.dart';
import '../../../core/services/app_logger.dart';
import 'transport_cube_details_base_screen.dart';

/// Pantalla de detalles para cubo en despacho de aduana
class CustomsDispatchDetailsScreen extends TransportCubeDetailsBaseScreen {
  const CustomsDispatchDetailsScreen({
    super.key,
    required super.cubeId,
  });

  @override
  State<CustomsDispatchDetailsScreen> createState() => _CustomsDispatchDetailsScreenState();
}

class _CustomsDispatchDetailsScreenState extends TransportCubeDetailsBaseScreenState<CustomsDispatchDetailsScreen> {
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
    // No mostrar botón flotante - usaremos solo el botón manual
    return const SizedBox.shrink();
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
                const Icon(Icons.local_shipping),
                const SizedBox(width: 8),
                Text(
                  'Despacho en Aduana',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Guías en el cubo: ${details.guides.length}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Para enviar el cubo a tránsito, selecciónalo en la lista principal y usa el botón "Enviar a tránsito".',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showHistory() async {
    final history = await context.read<TransportCubeProvider>().getCubeHistory(widget.cubeId);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSendToTransit(BuildContext context, TransportCubeDetails details) async {
    final guidesList = details.guides.map((g) => g.packageCode).join('\n• ');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enviar cubo a tránsito'),
        content: Text(
          'Se enviará el cubo a tránsito. El backend ya actualiza los estados de las guías automáticamente.\n\n'
          'Guías incluidas:\n\n• $guidesList\n\n'
          '¿Desea continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enviar a tránsito'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      AppLogger.log(
        'Starting send-to-transit flow for cube ${widget.cubeId}',
        source: 'CustomsDispatchDetailsScreen',
      );
      
      final provider = context.read<TransportCubeProvider>();
      
      // Cambiar estado del cubo a Sent
      provider.toggleCubeSelection(widget.cubeId);
      final cubeResp = await provider.changeSelectedCubesState(VisualStates.sent);

      if (!mounted) return;

      if (cubeResp.isSuccessful) {
        setState(() {});
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cubeResp.messageDetail ?? cubeResp.message ?? '✅ Cubo enviado a tránsito'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cubeResp.messageDetail ?? cubeResp.message ?? '❌ Error al cambiar estado del cubo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error en el proceso: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}