import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/transport_cube_provider.dart';
import '../models/transport_cube_details.dart';
import 'transport_cube_details_base_screen.dart';

/// Pantalla de detalles para cubo en despacho de aduana
class CustomsDispatchDetailsScreen extends TransportCubeDetailsBaseScreen {
  const CustomsDispatchDetailsScreen({
    super.key,
    required super.cubeId,
  });

  @override
  State<CustomsDispatchDetailsScreen> createState() =>
      _CustomsDispatchDetailsScreenState();
}

class _CustomsDispatchDetailsScreenState
    extends TransportCubeDetailsBaseScreenState<CustomsDispatchDetailsScreen> {

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
    final history =
    await context.read<TransportCubeProvider>().getCubeHistory(widget.cubeId);

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
}
