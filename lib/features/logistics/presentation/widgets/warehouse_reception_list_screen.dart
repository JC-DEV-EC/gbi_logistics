import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/guide_provider.dart';
import '../helpers/error_helper.dart';
import '../helpers/date_helper.dart';
import 'loading_indicator.dart';
import '../../models/operation_models.dart';

/// Widget especializado para mostrar lista de guías en recepción de bodega
class WarehouseReceptionListScreen extends StatefulWidget {
  final String title;
  final String status;
  final bool showHistoric;
  final bool hideValidated; // oculta validadas/ despachadas (uso en recepción)

  const WarehouseReceptionListScreen({
    Key? key,
    required this.title,
    required this.status,
    this.showHistoric = false,
    this.hideValidated = false,
  }) : super(key: key);

  @override
  State<WarehouseReceptionListScreen> createState() => _WarehouseReceptionListScreenState();
}

class _WarehouseReceptionListScreenState extends State<WarehouseReceptionListScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar automáticamente según estado y modo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Siempre cargar para TransitToWarehouse (Recepción en Bodega)
      // Al estar en tránsito, las guías deberían estar en estado DispatchedFromCustoms
      if (widget.status == TrackingStateType.transitToWarehouse) {
        _loadGuides();
      }
    });
  }

  Future<void> _loadGuides() async {
      await context.read<GuideProvider>().loadGuides(
        page: 1,
        pageSize: 50,
        status: TrackingStateType.transitToWarehouse,
        hideValidated: widget.hideValidated,
      );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GuideProvider>();
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _loadGuides,
      child: provider.isLoading
          ? const LoadingIndicator(
              message: 'Cargando guías...',
            )
          : provider.error != null
              ? ErrorHelper.buildErrorWidget(
                  error: provider.error!,
                  onRetry: _loadGuides,
                )
              : _buildGuideList(context),
    );
  }

  Widget _buildGuideList(BuildContext context) {
    final provider = context.watch<GuideProvider>();
    final theme = Theme.of(context);

    if (provider.guides.isEmpty) {
      return Center(
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
              widget.status == 'TransitToWarehouse'
                ? 'No hay guías en tránsito a bodega'
                : 'No hay guías en este estado',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.status == 'TransitToWarehouse'
                ? 'Las guías aparecerán aquí cuando sean despachadas desde aduana'
                : 'Escanea o busca una guía para continuar',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Ordenar guías: primero las escaneadas/seleccionadas
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

        return Card(
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
                      : theme.colorScheme.outline.withOpacity(0.2),
                  width: uiState == 'scanned' || isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
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
                              DateHelper.formatDateTime(guide.updateDateTime),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
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
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Chip(
                            label: Text(guide.stateLabel ?? 'Desconocido'),
                            backgroundColor: theme.colorScheme.surfaceVariant,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showGuideDetails(BuildContext context, dynamic guide) {
    final theme = Theme.of(context);

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

  Widget _buildDetailRow(BuildContext context, String label, String value, IconData icon) {
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