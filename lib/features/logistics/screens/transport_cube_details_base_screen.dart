import 'package:flutter/material.dart';
import '../models/guide_transport_cube_state.dart';
import '../models/transport_cube_state.dart';
import 'package:provider/provider.dart';
import '../providers/transport_cube_provider.dart';
import '../presentation/helpers/error_helper.dart';
import '../presentation/helpers/date_helper.dart';
import '../presentation/widgets/loading_indicator.dart';
import '../presentation/widgets/state_badge.dart';
import '../presentation/widgets/guide_status_indicator.dart';
import '../presentation/widgets/guide_counter.dart';
import '../models/transport_cube_details.dart';

/// Pantalla base para detalles de cubo de transporte
abstract class TransportCubeDetailsBaseScreen extends StatefulWidget {
  final int cubeId;

  const TransportCubeDetailsBaseScreen({
    super.key,
    required this.cubeId,
  });
}

abstract class TransportCubeDetailsBaseScreenState<T extends TransportCubeDetailsBaseScreen>
    extends State<T> {
  late Future<TransportCubeDetails> _detailsFuture;
  
  @override
  void initState() {
    super.initState();
    _detailsFuture = _loadDetails();
  }

  Future<TransportCubeDetails> _loadDetails() async {
    final response = await context.read<TransportCubeProvider>().service
        .getTransportCubeDetails(widget.cubeId, suppressAuthHandling: true);

    if (!mounted) throw Exception('Widget desmontado');
    
    if (!response.isSuccessful || response.content == null) {
      throw Exception(response.messageDetail ?? response.message ?? 'No se pudieron cargar los detalles');
    }

    return response.content!;
  }

  Future<void> _refreshDetails() async {
    await refreshDetails();
  }

  /// Método protegido para recargar detalles desde clases hijas
  @protected
  Future<void> refreshDetails({bool withDelay = true}) async {
    if (withDelay) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    setState(() {
      _detailsFuture = _loadDetails();
    });
  }

  /// Widget para acciones específicas del flujo (opcional)
  Widget buildActionButton(TransportCubeDetails details) => const SizedBox.shrink();

  /// Widget para acciones adicionales en AppBar
  List<Widget>? buildAppBarActions() => null;

  /// Widget para controles adicionales específicos del flujo
  Widget? buildAdditionalControls(TransportCubeDetails details) => null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Cubo #${widget.cubeId}'),
        actions: buildAppBarActions(),
      ),
      floatingActionButton: FutureBuilder<TransportCubeDetails>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return buildActionButton(snapshot.data!);
          }
          return const SizedBox.shrink();
        },
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDetails,
        child: FutureBuilder<TransportCubeDetails>(
          future: _detailsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingIndicator(
                message: 'Cargando detalles...',
              );
            }

            if (snapshot.hasError) {
              return ErrorHelper.buildErrorWidget(
                error: snapshot.error.toString(),
                onRetry: () => setState(() {
                  _detailsFuture = _loadDetails();
                }),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: Text('No se encontraron detalles'));
            }

            return _buildDetails(context, snapshot.data!);
          },
        ),
      ),
    );
  }

  Widget _buildDetails(BuildContext context, TransportCubeDetails details) {
    final theme = Theme.of(context);
    final cube = details.transportCube;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Información del cubo
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Estado actual:',
                      style: theme.textTheme.titleMedium,
                    ),
                    StateBadge(
                      state: cube.state,
                      label: cube.stateLabel ?? TransportCubeState.getLabel(cube.state),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Fecha de registro: ${DateHelper.formatDateTime(cube.registerDateTime)}',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                GuideCounter(
                  total: details.guides.length,
                  processed: details.guides.where((g) => g.state != GuideTransportCubeState.ENTERED).length,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Controles adicionales específicos del flujo
        if (buildAdditionalControls(details) != null) ...[
          buildAdditionalControls(details)!,
          const SizedBox(height: 16),
        ],

        // Lista de guías
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Guías',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              if (details.guides.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text('No hay guías en este cubo'),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: details.guides.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final guide = details.guides[index];
                    return ListTile(
                      title: Text(
                        guide.packageCode,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: GuideStatusIndicator(
                        state: guide.state,
                        stateLabel: guide.stateLabel ?? GuideTransportCubeState.getLabel(guide.state),
                        showLabel: true,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => _buildGuideActions(context, guide),
                          );
                        },
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuideActions(BuildContext context, dynamic guide) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Mover a otro cubo'),
            onTap: () {
              Navigator.pop(context);
              _showMoveGuideDialog(context, guide);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Eliminar del cubo'),
            textColor: Colors.red,
            iconColor: Colors.red,
            onTap: () {
              Navigator.pop(context);
              _showRemoveGuideDialog(context, guide);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showMoveGuideDialog(BuildContext context, dynamic guide) async {
    final provider = context.read<TransportCubeProvider>();
    // Implementar lógica de mover guía
  }

  Future<void> _showRemoveGuideDialog(BuildContext context, dynamic guide) async {
    final provider = context.read<TransportCubeProvider>();
    // Implementar lógica de eliminar guía
  }
}