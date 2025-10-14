import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/guide_provider.dart';
import '../helpers/error_helper.dart';
import '../helpers/date_helper.dart';
import 'loading_indicator.dart';
import '../../models/operation_models.dart';

/// Pantalla para mostrar lista de guías en recepción de bodega
class WarehouseReceptionListScreen extends StatefulWidget {
  final String title;
  final String status;
  final bool showHistoric;
  final bool hideValidated; // oculta validadas/despachadas (uso en recepción)

  const WarehouseReceptionListScreen({
    super.key,
    required this.title,
    required this.status,
    this.showHistoric = false,
    this.hideValidated = false,
  });

  @override
  State<WarehouseReceptionListScreen> createState() =>
      _WarehouseReceptionListScreenState();
}

class _WarehouseReceptionListScreenState
    extends State<WarehouseReceptionListScreen> {
  @override
  void initState() {
    super.initState();

    // Cargar automáticamente si el estado es TransitToWarehouse (Recepción en Bodega)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.status == TrackingStateType.transitToWarehouse) {
        _loadGuides();
      }
    });
  }

  /// Llamada al provider para cargar las guías
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

    return RefreshIndicator(
      onRefresh: _loadGuides,
      child: provider.isLoading
          ? const LoadingIndicator(message: 'Cargando guías...')
          : provider.error != null
          ? ErrorHelper.buildErrorWidget(
        error: provider.error!,
        onRetry: _loadGuides,
      )
          : SizedBox.expand(
        child: _buildGuideList(context),
      ),
    );
  }

  /// Construye la lista de guías
  Widget _buildGuideList(BuildContext context) {
    final provider = context.watch<GuideProvider>();
    final theme = Theme.of(context);

    if (provider.guides.isEmpty) {
      return _buildEmptyState(theme);
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

return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: guides.length,
      cacheExtent: 200, // Aumentar cache para mejor rendimiento
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        if (index > 0) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildGuideCard(context, guides[index]),
          );
        }
        final guide = guides[index];
        return _buildGuideCard(context, guide);
      },
    );
  }

  /// Estado vacío cuando no hay guías
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 64, color: theme.colorScheme.outline),
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

  /// Card para cada guía
  Widget _buildGuideCard(BuildContext context, dynamic guide) {
    final provider = context.watch<GuideProvider>();
    final theme = Theme.of(context);

    final uiState = provider.getGuideUiState(guide.code ?? '');
    final code = guide.code ?? '';
    final isSelected = code.isNotEmpty && provider.isGuideSelected(code);

    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () {},  // No se requiere acción al tocar
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
              _buildCardHeader(context, guide),
              const SizedBox(height: 16),
              _buildCardBody(theme, guide),
            ],
          ),
        ),
      ),
    );
  }

  /// Encabezado de la tarjeta
  Widget _buildCardHeader(BuildContext context, dynamic guide) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            'Guía ${guide.code ?? '—'}',
            style: theme.textTheme.titleLarge,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          color: Colors.red,
          tooltip: 'Quitar guía',
          onPressed: () {
            final provider = context.read<GuideProvider>();
            final code = guide.code as String?;
            if (code != null) {
              // Si estaba seleccionada para procesar, quitarla de la selección
              if (provider.isGuideSelected(code)) {
                provider.toggleGuideSelection(code);
              }
              // Limpiar estado UI y remover de la lista principal
              provider.removeGuideUiState(code);
              provider.setGuides(
                provider.guides.where((g) => g.code != code).toList(),
              );
            }
          },
        ),
      ],
    );
  }

  /// Cuerpo de la tarjeta
  Widget _buildCardBody(ThemeData theme, dynamic guide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (guide.subcourierName != null) ...[
          Row(
            children: [
              Icon(Icons.local_shipping_outlined,
                  size: 20, color: theme.colorScheme.onSurfaceVariant),
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
            Icon(Icons.calendar_today_outlined,
                size: 20, color: theme.colorScheme.onSurfaceVariant),
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
            Icon(Icons.inventory_2_outlined,
                size: 20, color: theme.colorScheme.onSurfaceVariant),
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
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ],
        ),
      ],
    );
  }
}
