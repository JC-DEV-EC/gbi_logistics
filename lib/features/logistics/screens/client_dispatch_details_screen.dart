
import 'package:flutter/material.dart';
import '../../../core/services/app_logger.dart';
import 'package:provider/provider.dart';
import '../providers/transport_cube_provider.dart';
import '../providers/guide_provider.dart';
import '../providers/auth_provider.dart';
import '../models/transport_cube_details.dart';
import '../models/operation_models.dart';
import '../presentation/helpers/error_helper.dart';
import 'transport_cube_details_base_screen.dart';

/// Pantalla de detalles para cubo en despacho a cliente
class ClientDispatchDetailsScreen extends TransportCubeDetailsBaseScreen {
  const ClientDispatchDetailsScreen({
    super.key,
    required super.cubeId,
  });

  @override
  State<ClientDispatchDetailsScreen> createState() =>
      _ClientDispatchDetailsScreenState();
}

class _ClientDispatchDetailsScreenState
    extends TransportCubeDetailsBaseScreenState<ClientDispatchDetailsScreen> {
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

    final selectedSubcourierId =
        context.watch<GuideProvider>().selectedSubcourierId;

    return FloatingActionButton.extended(
      onPressed: selectedSubcourierId == null
          ? null
          : () => _confirmDispatch(context),
      icon: const Icon(Icons.local_shipping),
      label: const Text('Despachar a Cliente'),
    );
  }

  @override
  Widget? buildAdditionalControls(TransportCubeDetails details) {

    return Column(
      children: <Widget>[
        _buildGuideCard(context, details),
        const SizedBox(height: 16),
        _buildDispatchCard(context),
      ],
    );
  }

  /// Tarjeta con la información de las guías
  Widget _buildGuideCard(BuildContext context, dynamic details) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Información de Guías',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildGuideInfo(context, details),
          ],
        ),
      ),
    );
  }

  /// Tarjeta con la información del despacho
  Widget _buildDispatchCard(BuildContext context) {
    final guideProvider = context.watch<GuideProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Información del Despacho',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: 'Subcourier',
                hintText: 'Seleccione un subcourier',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              value: guideProvider.selectedSubcourierId,
              items: context.read<AuthProvider>().subcouriers.map((sub) {
                return DropdownMenuItem(
                  value: sub.id,
                  child: Text(sub.name ?? 'Subcourier ${sub.id}'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  context.read<GuideProvider>().setSelectedSubcourier(value);
                }
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Seleccione el subcourier que realizará la entrega al cliente final',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Diálogo de historial del cubo
  Future<void> _showHistory() async {
    final history = await context
        .read<TransportCubeProvider>()
        .getCubeHistory(widget.cubeId);

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

  /// Info resumen de las guías
  Widget _buildGuideInfo(BuildContext context, dynamic details) {
    final theme = Theme.of(context);

    Widget buildRow(IconData icon, String label, String value) {
      return Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildRow(Icons.checklist, 'Total de guías:', '${details.guides.length}'),
        const SizedBox(height: 8),
        buildRow(Icons.person_outline, 'Clientes únicos:',
            '${details.guides.map((g) => g.clientId).toSet().length}'),
        const SizedBox(height: 8),
        buildRow(Icons.location_on_outlined, 'Direcciones únicas:',
            '${details.guides.map((g) => g.deliveryAddress).toSet().length}'),
      ],
    );
  }

  /// Confirmar despacho
  Future<void> _confirmDispatch(BuildContext context) async {
    AppLogger.log('Iniciando proceso de despacho', source: 'ClientDispatchDetailsScreen');
    final selectedSubcourierId =
        context.read<GuideProvider>().selectedSubcourierId;
    if (selectedSubcourierId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar despacho'),
        content: const Text(
          '¿Está seguro que desea despachar este cubo?\n\n'
              'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Despachar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final details = context.read<TransportCubeProvider>().selectedCubeDetails;
    if (details == null) return;

    try {
      final guides = List<String>.from(details.guides.map((g) => g.packageCode));
      final request = DispatchGuideToClientRequest(
        subcourierId: selectedSubcourierId,
        guides: guides,
      );
      final response = await context.read<GuideProvider>().dispatchToClient(request);

      if (!mounted) return;
      AppLogger.log(
        'Respuesta del despacho:\n'
        '- Exitoso: ${response.isSuccessful}\n'
        '- Mensaje: ${response.messageDetail ?? response.message}',
        source: 'ClientDispatchDetailsScreen'
      );

      if (response.isSuccessful) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.messageDetail ?? response.message ?? '✅ Guías despachadas exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.messageDetail ?? response.message ?? '❌ Error al despachar guías'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHelper.showErrorSnackBar(context, e);
      }
    }
  }
}
