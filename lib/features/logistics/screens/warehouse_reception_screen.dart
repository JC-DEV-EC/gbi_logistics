import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/guide_provider.dart';
import '../presentation/widgets/app_drawer.dart';
import '../presentation/widgets/warehouse_reception_scan_box.dart';
import '../services/guide_details_service.dart';
import '../models/guide_details.dart';

/// Pantalla para recepción en bodega
///
/// Flujo:
/// 1. Lista guías en estado [TransitToWarehouse].
/// 2. Al escanear, actualiza a [ReceivedInLocalWarehouse].
class WarehouseReceptionScreen extends StatefulWidget {
  const WarehouseReceptionScreen({super.key});

  @override
  State<WarehouseReceptionScreen> createState() =>
      _WarehouseReceptionScreenState();
}

class _WarehouseReceptionScreenState extends State<WarehouseReceptionScreen> {
  final List<GuideDetails> _matchedGuides = [];
  bool _isLoading = false;

  Future<void> _fetchGuideDetails(String code) async {
    setState(() => _isLoading = true);

    try {
      final service = context.read<GuideDetailsService>();
      final response = await service.getGuideDetails(code);

      if (response.isSuccessful && response.content != null) {
        // Verificar si la guía ya existe en la lista
        final exists = _matchedGuides.any((g) => g.guideCode == response.content!.guideCode);
        if (!exists) {
          setState(() {
            // Agregar la nueva guía al inicio de la lista
            _matchedGuides.insert(0, response.content!);
          });
        }

        // Mostrar mensaje de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Guía recibida correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recepción en Bodega')),
      drawer: const AppDrawer(),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            /// Indicador de carga superior
            Consumer<GuideProvider>(
              builder: (context, provider, _) {
                return provider.isLoading
                    ? const LinearProgressIndicator()
                    : const SizedBox.shrink();
              },
            ),

            /// Caja de escaneo
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Consumer<GuideProvider>(
                builder: (context, provider, _) {
                  return WarehouseReceptionScanBox(
                    onComplete: (scanned) async {
                      if (scanned.isEmpty) return;
                      await _fetchGuideDetails(scanned.first);
                    },
                  );
                },
              ),
            ),

            // Ya no necesitamos el botón de recepción porque ahora es inmediato

            /// Lista de guías escaneadas
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _matchedGuides.isEmpty
                  ? const Center(
                child: Text('Escanee guías para comenzar'),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _matchedGuides.length,
                itemBuilder: (context, index) {
                  final guide = _matchedGuides[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Guía ${guide.guideCode ?? '—'}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                    Icons.local_shipping_outlined,
                                    size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  guide.subcourierName ??
                                      guide.courierName ??
                                      '',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('dd/MM/yyyy HH:mm')
                                      .format(guide.updateDateTime),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                    Icons.inventory_2_outlined,
                                    size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Paquetes: ${guide.packages}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium,
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets
                                      .symmetric(
                                      horizontal: 12,
                                      vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    borderRadius:
                                    BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    guide.stateLabel ?? '',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
