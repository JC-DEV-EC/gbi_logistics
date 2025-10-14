import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/guide_provider.dart';
import '../presentation/widgets/app_drawer.dart';
import '../presentation/widgets/client_dispatch_scan_box.dart';
import '../presentation/widgets/subcourier_client_selector.dart';
import '../presentation/helpers/date_helper.dart';
import '../models/operation_models.dart';

/// Pantalla para despacho a cliente
class ClientDispatchScreen extends StatefulWidget {
  const ClientDispatchScreen({super.key});

  @override
  State<ClientDispatchScreen> createState() => _ClientDispatchScreenState();
}

class _ClientDispatchScreenState extends State<ClientDispatchScreen> {
  
  /// Reinicia el proceso completo
  Future<void> _refreshProcess(GuideProvider guideProvider) async {
    // Simular delay para mostrar el indicador de refresh
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Reiniciar el estado completo
    guideProvider.unlockSelectors();
    guideProvider.resetSelections();
    guideProvider.clearSelectedGuides();
    guideProvider.setGuides([]);
    guideProvider.errorNotifier.value = null;
    
    // Mostrar mensaje de confirmación
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proceso reiniciado - Seleccione un subcourier para comenzar'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Despacho en Bodega'),
        ),
        drawer: const AppDrawer(),
        onEndDrawerChanged: (isOpen) {
          if (!isOpen && context.mounted) {
            final provider = context.read<GuideProvider>();
            if (provider.lastOperationSuccessful) {
              _showSuccessMessage(context, 'Guía despachada exitosamente');
              provider.clearLastOperationStatus();
            }
          }
        },
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Builder(
              builder: (context) => RepaintBoundary(
                child: Consumer2<GuideProvider, AuthProvider>(
                  builder: (context, guideProvider, authProvider, _) {
                    return RefreshIndicator(
                      onRefresh: () => _refreshProcess(guideProvider),
                      child: Column(
                        children: [
                          Container(
                            color: Theme.of(context).colorScheme.surface,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildCourierSelector(guideProvider),
                                _buildScanBox(guideProvider),
                                _buildErrorMessage(guideProvider),
                              ],
                            ),
                          ),
                          Expanded(
                            child: guideProvider.guides.isEmpty
                                ? _buildEmptyState()
                                : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: guideProvider.guides.length,
                              itemBuilder: (context, index) =>
                                  _buildGuideCard(guideProvider.guides[index]),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Construye el widget para mostrar cuando no hay guías
  Widget _buildEmptyState() {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícono de archivo/documento
              Icon(
                Icons.folder_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              // Título principal
              Text(
                'No hay guías agregadas',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              // Subtítulo/instrucción
              Text(
                'Escanee o ingrese los códigos de las guías',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCourierSelector(GuideProvider guideProvider) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        child: SubcourierClientSelector(
          isLocked: guideProvider.selectorsLocked,
          onSubcourierSelected: (subcourierId) {
            if (subcourierId != null) {
              guideProvider.setSelectedSubcourier(subcourierId);
            }
          },
          onClientSelected: (clientId) {
            guideProvider.setSelectedClient(clientId);
          },
          onRequiresClientChanged: (requiresClient) {
            guideProvider.setRequiresClient(requiresClient);
          },
        ),
      ),
    );
  }

  Widget _buildScanBox(GuideProvider guideProvider) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        child: guideProvider.isLoading
            ? const LinearProgressIndicator()
            : const ClientDispatchScanBox(),
      ),
    );
  }

  Widget _buildErrorMessage(GuideProvider guideProvider) {
    return ValueListenableBuilder<String?>(
      valueListenable: guideProvider.errorNotifier,
      builder: (context, error, _) {
        if (error == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            error,
            style: const TextStyle(color: Colors.red),
          ),
        );
      },
    );
  }

  Widget _buildGuideCard(GuideInfo guide) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGuideHeader(guide),
            const SizedBox(height: 8),
            _buildGuideDetails(guide),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideHeader(GuideInfo guide) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Guía ${guide.code}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          color: Colors.red,
          onPressed: () {
            final guideCode = guide.code;
            if (guideCode != null) {
              final provider = context.read<GuideProvider>();
              // Quitar la guía de la lista de guías seleccionadas
              if (provider.isGuideSelected(guideCode)) {
                provider.toggleGuideSelection(guideCode);
              }
              // Quitar la guía del estado UI
              provider.removeGuideUiState(guideCode);
              // Quitar la guía de la lista principal
              final newGuides = provider.guides.where((g) => g.code != guideCode).toList();
              provider.setGuides(newGuides);
              
              // Si no quedan guías, desbloquear selectores
              if (newGuides.isEmpty) {
                provider.unlockSelectors();
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildGuideDetails(GuideInfo guide) {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.local_shipping_outlined, size: 18),
            const SizedBox(width: 8),
            Text(
              guide.subcourierName ?? '',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18),
            const SizedBox(width: 8),
            Text(
              DateHelper.formatDateTime(guide.updateDateTime),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.inventory_2_outlined, size: 18),
            const SizedBox(width: 8),
            Text(
              'Paquetes: ${guide.packages}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                guide.stateLabel ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}