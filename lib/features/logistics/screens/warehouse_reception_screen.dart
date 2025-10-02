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
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Indicador de carga
            Consumer<GuideProvider>(
              builder: (context, provider, _) => provider.isLoading
                  ? const LinearProgressIndicator()
                  : const SizedBox.shrink(),
            ),
            
            // Caja de escaneo con Flexible
            Flexible(
              flex: 0,
              fit: FlexFit.loose,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
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
      ),
    );
  }
}
