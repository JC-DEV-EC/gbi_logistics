import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/guide_provider.dart';
import '../helpers/error_helper.dart';
import '../helpers/date_helper.dart';
import 'loading_indicator.dart';

/// Widget especializado para mostrar lista de guías en despacho a cliente
class ClientDispatchListScreen extends StatefulWidget {
  const ClientDispatchListScreen({super.key});

  @override
  State<ClientDispatchListScreen> createState() =>
      _ClientDispatchListScreenState();
}

class _ClientDispatchListScreenState extends State<ClientDispatchListScreen> {
  // Estados permitidos para despacho a cliente y sus etiquetas
  static const Map<String, String> stateLabels = {
    'ReceivedInLocalWarehouse': 'Recibido en Bodega',
    'DispatchedFromCustomsWithOutCube': 'Despachado sin Cubo',
  };

  String _selectedState = 'ReceivedInLocalWarehouse'; // Estado inicial

  @override
  void initState() {
    super.initState();
    // Cargar guías al inicio y cuando se monta el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<GuideProvider>()
          .setClientDispatchFilterState(_selectedState);
      _loadGuides();
    });
  }

  Future<void> _loadGuides() async {
    // Cargar solo las guías del estado seleccionado
    await context.read<GuideProvider>().loadGuides(
      page: 1,
      pageSize: 50,
      status: _selectedState,
      hideValidated: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GuideProvider>();
    return Column(
      children: [
        // Filtro de estados
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SegmentedButton<String>(
            segments: stateLabels.entries
                .map(
                  (e) => ButtonSegment<String>(
                value: e.key,
                label: Text(e.value),
              ),
            )
                .toList(),
            selected: {_selectedState},
            onSelectionChanged: (Set<String> selection) {
              final newState = selection.first;
              setState(() {
                _selectedState = newState;
              });
              context
                  .read<GuideProvider>()
                  .setClientDispatchFilterState(newState);
              _loadGuides();
            },
          ),
        ),

        // Lista con refresh
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadGuides,
            child: provider.isLoading
                ? const LoadingIndicator(message: 'Cargando guías...')
                : provider.error != null
                ? ErrorHelper.buildErrorWidget(
              error: provider.error!,
              onRetry: _loadGuides,
            )
                : _buildGuideList(context),
          ),
        ),
      ],
    );
  }

  Widget _buildGuideList(BuildContext context) {
    final provider = context.watch<GuideProvider>();
    final theme = Theme.of(context);

    if (provider.guides.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No hay guías listas para despacho',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedState == 'ReceivedInLocalWarehouse'
                    ? 'No hay guías recibidas en bodega'
                    : 'No hay guías despachadas sin cubo',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Ordenar: primero las escaneadas/seleccionadas
    final guides = List.of(provider.guides);
    guides.sort((a, b) {
      final aState = provider.getGuideUiState(a.code ?? '');
      final bState = provider.getGuideUiState(b.code ?? '');
      if (aState == 'scanned' && bState != 'scanned') return -1;
      if (bState == 'scanned' && aState != 'scanned') return 1;
      return 0;
    });

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: guides.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final guide = guides[index];
        final uiState = provider.getGuideUiState(guide.code ?? '');
        final code = guide.code ?? '';
        final isSelected = code.isNotEmpty && provider.isGuideSelected(code);

        return RepaintBoundary(
          child: Card(
            clipBehavior: Clip.hardEdge,
            child: InkWell(
              onTap: () {
                // Aquí iría la navegación a detalles de guía si es necesario
              },
              onLongPress: () {
                if (code.isNotEmpty) provider.toggleGuideSelection(code);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: uiState == 'scanned'
                        ? theme.colorScheme.primary
                        : isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 51),
                    width: uiState == 'scanned' || isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con código + botón info
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Guía ${guide.code ?? '—'}',
                            style: theme.textTheme.titleLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () => _showGuideDetails(context, guide),
                          tooltip: 'Ver detalles',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Info detallada
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (guide.subcourierName != null) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.local_shipping_outlined,
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  guide.subcourierName!,
                                  style:
                                  theme.textTheme.bodyLarge?.copyWith(
                                    color: theme
                                        .colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 20,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                DateHelper.formatDateTime(
                                    guide.updateDateTime),
                                style:
                                theme.textTheme.bodyLarge?.copyWith(
                                  color: theme
                                      .colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 20,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Paquetes: ${guide.packages}',
                                style:
                                theme.textTheme.bodyLarge?.copyWith(
                                  color: theme
                                      .colorScheme.surfaceContainerHighest,
                                ),
                              ),
                            ),
                            Chip(
                              label: Text(
                                  guide.stateLabel ?? 'Desconocido'),
                              backgroundColor: theme
                                  .colorScheme.surfaceContainerHighest,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showGuideDetails(BuildContext context, dynamic guide) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Guía ${guide.code ?? '—'}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                context,
                'Estado',
                guide.stateLabel ?? 'Desconocido',
                Icons.local_shipping_outlined,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                'Fecha última actualización',
                DateHelper.formatDateTime(guide.updateDateTime),
                Icons.calendar_today_outlined,
              ),
              if (guide.subcourierName != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  context,
                  'Subcourier',
                  guide.subcourierName!,
                  Icons.person_outline,
                ),
              ],
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                'Paquetes',
                '${guide.packages}',
                Icons.inventory_2_outlined,
              ),
            ],
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

  Widget _buildDetailRow(
      BuildContext context,
      String label,
      String value,
      IconData icon,
      ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}