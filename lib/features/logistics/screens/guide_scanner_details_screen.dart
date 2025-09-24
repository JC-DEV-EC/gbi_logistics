import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Services
import '../services/app_sounds.dart';
import '../services/guide_details_service.dart';

// Models
import '../models/guide_details.dart';

// Widgets
import '../widgets/guide_details_scanner.dart';
import '../presentation/widgets/app_drawer.dart';

class GuideScannerDetailsScreen extends StatefulWidget {
  const GuideScannerDetailsScreen({super.key});

  @override
  State<GuideScannerDetailsScreen> createState() =>
      _GuideScannerDetailsScreenState();
}

class _GuideScannerDetailsScreenState extends State<GuideScannerDetailsScreen> {
  GuideDetails? _guideDetails;
  bool _isLoading = false;
  String? _error;
  String? _lastScannedCode;

  Future<void> _fetchGuideDetails(String code) async {
    debugPrint('----------------------------------------');
    debugPrint('[GuideScannerDetailsScreen] Iniciando búsqueda de guía: $code');
    // Evitar escaneos duplicados consecutivos
    if (_lastScannedCode == code) return;
    _lastScannedCode = code;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('[GuideScannerDetailsScreen] Llamando a servicio getGuideDetails');
      final service = context.read<GuideDetailsService>();
      final response = await service.getGuideDetails(code);

      debugPrint('[GuideScannerDetailsScreen] Respuesta recibida:');
      debugPrint('- isSuccessful: ${response.isSuccessful}');
      debugPrint('- messageDetail: ${response.messageDetail}');
      debugPrint('- content: ${response.content?.toJson()}');

      debugPrint('Actualizando estado con respuesta isSuccessful: ${response.isSuccessful}');
      setState(() {
        _isLoading = false;
        if (response.isSuccessful && response.content != null) {
          _guideDetails = response.content;
          _error = null;  // No mostrar error si es exitoso
          debugPrint('Guía cargada: ${_guideDetails?.toJson()}');
        } else {
          _guideDetails = null;
          _error = response.messageDetail;
          debugPrint('Error establecido: $_error');
        }
        debugPrint('[GuideScannerDetailsScreen] Estado actualizado:');
        debugPrint('- _guideDetails: ${_guideDetails?.toJson()}');
        debugPrint('- _error: $_error');
      });

      // Mostrar el messageDetail en un SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              response.messageDetail ?? 
                              response.message ?? 
                              'Error al buscar la guía',
                              style: const TextStyle(fontSize: 13),
                            ),
                            backgroundColor: response.isSuccessful ? Colors.green : Colors.red,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(8),
                          ),
        );
      }
    } catch (e) {
      debugPrint('[GuideScannerDetailsScreen] Error capturado: $e');
      setState(() {
        _guideDetails = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Guía'),
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Scanner Widget
          SizedBox(
            height: 120,
            child: GuideDetailsScannerWidget(
              onCodeScanned: _fetchGuideDetails,
            ),
          ),

          // Loading indicator o contenido
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[100]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_guideDetails != null)
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),  // Reducido el margen superior
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 6,
                    ),
                  ],
                ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Encabezado con estado
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.local_shipping_outlined,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _guideDetails!.stateLabel ?? 'Estado desconocido',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Información general
                        _DetailItem(title: 'Código de Guía', value: _guideDetails!.guideCode ?? 'N/A'),
                        _DetailItem(title: 'Courier', value: _guideDetails!.courierName ?? 'N/A'),
                        _DetailItem(title: 'Subcourier', value: _guideDetails!.subcourierName ?? 'N/A'),
                        _DetailItem(title: 'Mailbox', value: _guideDetails!.mailbox ?? 'N/A'),
                        _DetailItem(title: 'Dimensiones', value: _guideDetails!.dimensions ?? 'N/A'),
                        _DetailItem(title: 'Peso Total', value: '${_guideDetails!.totalWeight} kg'),
                        _DetailItem(
                          title: 'Última Actualización',
                          value: DateFormat('dd/MM/yyyy HH:mm').format(_guideDetails!.updateDateTime),
                        ),

                        // Paquetes
                        if (_guideDetails!.packageItems?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 24),
                          Text(
                            'Contenido del Paquete',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          ..._guideDetails!.packageItems!.map(
                                (item) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tracking: ${item.trackingNumber ?? 'N/A'}',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Peso: ${item.weight} kg'),
                                    Text('Volumen: ${item.volume} m³'),
                                    Text('Dimensiones: ${item.width}x${item.height}m'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// Widget para mostrar cada campo de detalle de la guía
class _DetailItem extends StatelessWidget {
  final String title;
  final String value;

  const _DetailItem({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
