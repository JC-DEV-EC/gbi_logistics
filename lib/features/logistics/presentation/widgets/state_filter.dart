import 'package:flutter/material.dart';
import '../../models/transport_cube_state.dart';

/// Widget para filtrar por estado de los cubos
class StateFilter extends StatelessWidget {
  final String selectedState;
  final ValueChanged<String> onStateChanged;
  final bool showHistoric;

  const StateFilter({
    super.key,
    required this.selectedState,
    required this.onStateChanged,
    this.showHistoric = true,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            context,
            TransportCubeState.created,
            'Despacho en Aduana',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            TransportCubeState.sent,
            'Tránsito a Bodega',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            TransportCubeState.downloading,
            'Recepción en Bodega',
          ),
          if (showHistoric) ...[
            const SizedBox(width: 8),
            _buildFilterChip(
              context,
              TransportCubeState.downloaded,
              'Histórico',
              isHistoric: true,
            ),
          ],
        ],
      ),
    );
  }

  /// Construye un chip de filtro individual
  Widget _buildFilterChip(
      BuildContext context,
      String state,
      String label, {
        bool isHistoric = false,
      }) {
    final isSelected = state == selectedState;
    final theme = Theme.of(context);
    final color = Color(TransportCubeState.getColor(state));

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (bool selected) {
        if (selected) onStateChanged(state);
      },
      avatar: isHistoric
          ? const Icon(Icons.history, size: 18)
          : Icon(
        TransportCubeState.getIcon(state),
        size: 18,
      ),
      showCheckmark: false,
      selectedColor: color.withValues(alpha: 31),
      labelStyle: TextStyle(
        color: isSelected ? color : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
