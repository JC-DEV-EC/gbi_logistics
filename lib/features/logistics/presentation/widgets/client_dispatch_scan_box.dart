import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/guide_provider.dart';
import '../../models/operation_models.dart';
import '../controllers/scan_controller.dart';

/// Widget para escaneo de guías en despacho a cliente
class ClientDispatchScanBox extends StatefulWidget {
  const ClientDispatchScanBox({super.key});

  @override
  State<ClientDispatchScanBox> createState() => _ClientDispatchScanBoxState();
}

class _ClientDispatchScanBoxState extends State<ClientDispatchScanBox> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScanController _scanController = ScanController();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    _scanController.dispose();
    super.dispose();
  }

  /// Procesa en lote las guías seleccionadas
  Future<void> _processBatchGuides(GuideProvider provider) async {
    final selectedGuides = provider.selectedGuides.toList();

    // Verificar que hay un subcourier seleccionado
    if (provider.selectedSubcourierId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Debe seleccionar un mensajero'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Llamar a dispatch-to-client
      final request = DispatchGuideToClientRequest(
        subcourierId: provider.selectedSubcourierId!,
        guides: selectedGuides,
      );

      final response = await provider.dispatchToClient(request);

      if (!mounted) return;

      if (response.isSuccessful) {
        // Feedback de éxito
        SystemSound.play(SystemSoundType.click);
        
        // Mostrar mensaje del backend
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response.messageDetail ?? response.message ?? 
            'Guías despachadas correctamente'),
          backgroundColor: Colors.green,
        ));

        // Limpiar selección y recargar lista
        provider.clearSelectedGuides();
        await provider.loadGuides(
          page: 1,
          pageSize: 50,
          status: 'ReceivedInLocalWarehouse',
        );
      } else {
        // Feedback de error
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response.messageDetail ?? response.message ?? 
            'Error al despachar guías'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error inesperado: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  /// Maneja la entrada de guías individuales
  Future<void> _handleGuideInput(String? guide, GuideProvider provider) async {
    if (guide == null || guide.isEmpty) return;

    final cleanGuide = guide.trim();
    if (cleanGuide.isEmpty) return;

    await _scanController.processScan(() async {
      try {
        // Buscar primero en la lista actual
        final currentGuides = provider.guides;
        final localMatch = currentGuides
            .where((g) => g.code == cleanGuide)
            .toList();

        // Si la guía ya está en la lista, usarla
        if (localMatch.isNotEmpty) {
          SystemSound.play(SystemSoundType.click);
          provider.updateGuideUiState(cleanGuide, 'scanned');
          if (!provider.isGuideSelected(cleanGuide)) {
            provider.toggleGuideSelection(cleanGuide);
          }
          if (mounted) {
            _controller.clear();
          }
          return;
        }

        // Si no está en la lista, buscar en el backend usando searchQuery
        final guides = await provider.searchGuides(
          page: 1,
          pageSize: 50,
          status: 'ReceivedInLocalWarehouse',  // TODO: Usar TrackingStateType cuando se resuelva el ciclo de importación
          guideCode: cleanGuide,
        );

        final exactMatch = guides.where((g) => g.code == cleanGuide).firstOrNull;
        
        if (exactMatch != null) {
          SystemSound.play(SystemSoundType.click);
          provider.updateGuideUiState(cleanGuide, 'scanned');
          if (!provider.isGuideSelected(cleanGuide)) {
            provider.toggleGuideSelection(cleanGuide);
          }

          // Actualizar la lista local
          List<GuideInfo> newGuides = List.from(currentGuides);
          newGuides.insert(0, exactMatch); // Agregar al inicio
          provider.setGuides(newGuides);
        } else {
          HapticFeedback.heavyImpact();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '❌ La guía $cleanGuide no está disponible para despacho',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }

        if (mounted) {
          _controller.clear();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error al procesar la guía'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          _controller.clear();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<GuideProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Botón de procesar guías seleccionadas
        if (provider.selectedGuides.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: FilledButton.icon(
              onPressed: () => _processBatchGuides(provider),
              icon: const Icon(Icons.check_circle_outline),
              label: Text('Procesar ${provider.selectedGuides.length} guías'),
            ),
          ),
        ],

        // Campo de entrada
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Escanee o ingrese el código de la guía',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: InputBorder.none,
              suffixIcon: Icon(
                Icons.qr_code_scanner,
                color: theme.colorScheme.primary,
              ),
            ),
            onChanged: (value) {
              if (value.endsWith('\n')) {
                _handleGuideInput(value.replaceAll('\n', ''), provider);
              }
            },
            onSubmitted: (value) => _handleGuideInput(value, provider),
          ),
        ),
      ],
    );
  }
}
