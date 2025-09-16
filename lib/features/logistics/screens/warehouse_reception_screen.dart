import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../presentation/widgets/warehouse_reception_list_screen.dart';
import '../presentation/widgets/warehouse_reception_scan_box.dart';
import '../providers/guide_provider.dart';
import '../models/operation_models.dart';

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
      body: SafeArea(
        child: Column(
          children: [
            // Indicador de carga
            Consumer<GuideProvider>(
              builder: (context, provider, _) => provider.isLoading
                  ? const LinearProgressIndicator()
                  : const SizedBox.shrink(),
            ),

            // Caja de escaneo
            Padding(
              padding: const EdgeInsets.all(16),
              child: Consumer<GuideProvider>(
                builder: (context, provider, _) {
                  return WarehouseReceptionScanBox(
                    onComplete: (scanned) async {
                      if (scanned.isEmpty) return;

                      // Actualizar directamente a ReceivedInLocalWarehouse
                      final request = UpdateGuideStatusRequest(
                        guides: scanned,
                        newStatus: TrackingStateType.receivedInLocalWarehouse,
                      );

                      final response = await provider.updateGuideStatus(request);
                      
                      if (!context.mounted) return;

                      // Mostrar mensaje del backend (éxito o error)
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(response.messageDetail ?? response.message ?? 
                          (response.isSuccessful ? 'Guías actualizadas correctamente' : 'Error al actualizar guías')),
                        backgroundColor: response.isSuccessful ? Colors.green : Colors.red,
                      ));

                      // Si fue exitoso, recargar la lista
                      if (response.isSuccessful) {
                        await provider.loadGuides(
                          page: 1,
                          pageSize: 50,
                          status: TrackingStateType.transitToWarehouse,
                        );
                      }
                    },
                  );
                },
              ),
            ),

            // Lista de guías
            const Expanded(
              child: WarehouseReceptionListScreen(
                title: 'Recepción en Bodega',
                status: TrackingStateType.transitToWarehouse,  // Muestra guías en tránsito a bodega
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
