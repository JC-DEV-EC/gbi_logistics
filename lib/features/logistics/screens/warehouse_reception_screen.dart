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
        child: SingleChildScrollView(
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
                          newStatus:
                          TrackingStateType.receivedInLocalWarehouse,
                        );

                        final response =
                        await provider.updateGuideStatus(request);

                        if (!context.mounted) return;

                        // Mostrar mensaje del backend con más detalle
                        // Siempre mostrar el messageDetail del servidor si existe
                        final serverMessage = response.messageDetail ?? response.message ?? '';

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              serverMessage.isNotEmpty
                                ? serverMessage
                                : response.isSuccessful
                                    ? 'Se actualizaron ${scanned.length} guías correctamente'
                                    : 'Error al actualizar las guías',
                              style: const TextStyle(fontSize: 14),
                            ),
                            backgroundColor: !response.isSuccessful ? Colors.red : Colors.green,
                            duration: serverMessage.isNotEmpty
                                ? const Duration(seconds: 10)
                                : const Duration(seconds: 4),
                          ),
                        );

                        // Incluso con errores parciales, recargar para mostrar las actualizadas
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

              // Lista de guías
              const SizedBox(
                height: 300, // Altura fija para la lista
                child: WarehouseReceptionListScreen(
                  title: 'Recepción en Bodega',
                  status: TrackingStateType.transitToWarehouse,
                  showHistoric: false,
                  hideValidated: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
