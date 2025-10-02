import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../presentation/widgets/warehouse_reception_list_screen.dart';
import '../presentation/widgets/warehouse_reception_scan_box.dart';
import '../providers/guide_provider.dart';
import '../models/operation_models.dart';
import '../presentation/widgets/app_drawer.dart';

/// Pantalla para recepción en bodega
/// Flujo:
/// 1. Lista guías en estado TransitToWarehouse
/// 2. Al escanear, actualiza a ReceivedInLocalWarehouse
class WarehouseReceptionScreen extends StatelessWidget {
  const WarehouseReceptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recepción en Bodega'),
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Stack(
          children: [
            // Indicador de carga en la parte superior
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Consumer<GuideProvider>(
                builder: (context, provider, _) => provider.isLoading
                    ? const LinearProgressIndicator()
                    : const SizedBox.shrink(),
              ),
            ),
            
            // Contenido principal
            Column(
              children: [
                // Caja de escaneo
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Consumer<GuideProvider>(
                    builder: (context, provider, _) {
                      return WarehouseReceptionScanBox(
                        onComplete: (scanned) async {
                          if (scanned.isEmpty) return;

                          // Ya se actualizó el estado dentro del ScanBox.
                          // Aquí solo recargamos la lista para reflejar cambios.
                          if (!context.mounted) return;
                          await provider.loadGuides(
                            page: 1,
                            pageSize: 50,
                            status: TrackingStateType.transitToWarehouse,
                          );
                        },
                      );
                    },
                  ),
                ),

                // Lista de guías - usar espacio restante
                Expanded(
                  child: const WarehouseReceptionListScreen(
                    title: 'Recepción en Bodega',
                    status: TrackingStateType.transitToWarehouse,
                    showHistoric: false,
                    hideValidated: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
