import 'package:flutter/material.dart';
import '../../models/guide_transport_cube_state.dart';

/// Widget que muestra el estado de una guía
class GuideStatusIndicator extends StatelessWidget {
  final String state;
  final String stateLabel;
  final bool showLabel;
  final bool useSmallIcon;

  const GuideStatusIndicator({
    super.key,
    required this.state,
    required this.stateLabel,
    this.showLabel = false,
    this.useSmallIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
final color = Color(GuideTransportCubeState.getColor(state));
final iconData = GuideTransportCubeState.getIcon(state);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          iconData,
          color: color,
          size: useSmallIcon ? 16 : 24,
        ),
        if (showLabel) ...[
          const SizedBox(width: 8),
          Text(
            stateLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onBackground,
            ),
          ),
        ],
      ],
    );
  }
}
