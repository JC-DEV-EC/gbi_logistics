import 'package:flutter/material.dart';

/// Widget que muestra un contador de guías con barra de progreso
class GuideCounter extends StatelessWidget {
  final int total;
  final int processed;

  const GuideCounter({
    super.key,
    required this.total,
    required this.processed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Proteger cuando total = 0
    final safeTotal = total == 0 ? 1 : total;
    final percentageValue = processed / safeTotal;
    final percentage = (percentageValue * 100).clamp(0, 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Guías: $processed/$total',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(width: 8),
            Text(
              '($percentage%)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentageValue.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}
