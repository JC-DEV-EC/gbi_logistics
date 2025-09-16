import 'package:flutter/material.dart';
import '../../models/transport_cube_state.dart';

/// Widget que muestra un badge con el estado de un cubo
class StateBadge extends StatelessWidget {
  final String state;
  final String label;

  const StateBadge({
    super.key,
    required this.state,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
final color = Color(TransportCubeState.getColor(state));

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
TransportCubeState.getIcon(state),
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
