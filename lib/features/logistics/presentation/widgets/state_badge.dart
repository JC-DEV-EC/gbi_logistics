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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14.0,
            ),
          ),
        ],
      ),
    );
  }
}
