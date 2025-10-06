import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/transport_cube_provider.dart';
import '../presentation/helpers/error_helper.dart';
import '../presentation/helpers/date_helper.dart';
import '../presentation/widgets/loading_indicator.dart';
import '../presentation/widgets/state_badge.dart';

/// Widget para listado de cubos de transporte
class TransportCubeListScreen extends StatefulWidget {
  final String title;
  final String initialState;
  final bool showHistoric;

  const TransportCubeListScreen({
    super.key,
    required this.title,
    required this.initialState,
    this.showHistoric = true,
  });

  @override
  State<TransportCubeListScreen> createState() =>
      _TransportCubeListScreenState();
}

class _TransportCubeListScreenState extends State<TransportCubeListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeAndLoad());
  }

  Future<void> _initializeAndLoad() async {
    await _loadCubes();
  }

  Future<void> _loadCubes() async {
    await context.read<TransportCubeProvider>().loadCubes();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransportCubeProvider>();

    developer.log(
      'Building TransportCubeListScreen:\n'
          '- Loading: ${provider.isLoading}\n'
          '- Error: ${provider.error}\n'
          '- Cubes count: ${provider.cubes.length}',
      name: 'TransportCubeListScreen',
    );

    return RefreshIndicator(
      onRefresh: _loadCubes,
      child: provider.isLoading
          ? const LoadingIndicator(message: 'Cargando cubos...')
          : provider.cubes.isNotEmpty
          ? _buildCubeList(context)
          : provider.error != null
          ? ErrorHelper.buildErrorWidget(
        error: provider.error!,
        onRetry: _loadCubes,
      )
          : _buildCubeList(context),
    );
  }

  Widget _buildCubeList(BuildContext context) {
    final provider = context.watch<TransportCubeProvider>();
    final theme = Theme.of(context);

    developer.log(
      '_buildCubeList called:\n'
          '- Provider loading: ${provider.isLoading}\n'
          '- Provider error: ${provider.error}\n'
          '- Provider cubes count: ${provider.cubes.length}\n'
          '- Selected state: ${provider.selectedState}',
      name: 'TransportCubeListScreen',
    );

    if (provider.cubes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay cubos en este estado',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: provider.cubes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
        final cube = provider.cubes[index];
        final isSelected = provider.isCubeSelected(cube.id);

        return RepaintBoundary(
          child: Card(
            clipBehavior: Clip.hardEdge,
            child: InkWell(
              onTap: () {
                if (widget.initialState == 'Sent' ||
                    widget.initialState == 'Created') {
                  developer.log(
                    'Tap on cube card - ID: ${cube.id} - Current selected: ${provider.isCubeSelected(cube.id)}',
                    name: 'TransportCubeListScreen',
                  );
                  provider.toggleCubeSelection(cube.id);
                } else {
                  Navigator.pushNamed(
                    context,
                    '/transport-cube/details',
                    arguments: cube.id,
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: isSelected
                      ? Border.all(
                    color: theme.colorScheme.primary,
                    width: 2,
                  )
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Cubo #${cube.id}',
                            style: theme.textTheme.titleLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Ver detalles',
                          icon: const Icon(Icons.visibility_outlined),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/transport-cube/details',
                              arguments: cube.id,
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        StateBadge(
                          state: cube.state,
                          label: cube.state, // Mostrar el estado directamente
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 24,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 20,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${cube.guides} guías',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 20,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateHelper.formatDateTime(cube.registerDateTime),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        if (cube.operatorName != null && cube.operatorName!.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                cube.operatorName!,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.category_outlined,
                              size: 20,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              cube.typeLabel ?? '',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
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
        ),
      ],
    );
  }
}
