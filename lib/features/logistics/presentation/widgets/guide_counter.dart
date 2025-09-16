import 'package:flutter/material.dart';

/// Widget que muestra un contador de guías
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
    final percentage = (processed / total * 100).round();

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
            value: processed / total,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceVariant,
          ),
        ),
      ],
    );
  }
}
