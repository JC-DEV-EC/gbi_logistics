import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/guide_provider.dart';
import '../../models/operation_models.dart';
import '../controllers/scan_controller.dart';
import '../../providers/auth_provider.dart';
import '../../services/app_sounds.dart';

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
    // Capture messenger before awaits to avoid context across async gaps
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (!mounted) return;
    final selectedGuides = provider.selectedGuides.toList();

    // Verificar que hay un subcourier seleccionado SOLO al procesar
    if (provider.selectedSubcourierId == null) {
      await AppSounds.error();
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione un subcourier'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar que todas las guías pertenezcan al subcourier seleccionado
    final auth = context.read<AuthProvider>();
    final selectedSub = auth.subcouriers.firstWhere((s) => s.id == provider.selectedSubcourierId);

    final currentGuides = provider.guides;
    final selectedGuideInfos = currentGuides.where((g) => selectedGuides.contains(g.code)).toList();

    // Detectar guías con subcourier diferente
    final mismatches = selectedGuideInfos
        .where((g) => (g.subcourierName ?? '').trim() != (selectedSub.name ?? '').trim())
        .toList();

    if (mismatches.isNotEmpty) {
      // Construir mensaje de alerta
      final sample = mismatches.take(3).map((g) => g.code).join(', ');
      final extra = mismatches.length > 3 ? ' y ${mismatches.length - 3} más' : '';
      if (!mounted) return;
      await AppSounds.error();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Las guías $sample$extra pertenecen a otro subcourier'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    try {
      // Llamar a dispatch-to-client cuando todo está consistente
      final request = DispatchGuideToClientRequest(
        subcourierId: provider.selectedSubcourierId!,
        guides: selectedGuides,
      );

      final response = await provider.dispatchToClient(request);

      if (!mounted) return;

      if (response.isSuccessful) {
        debugPrint('[DEBUG] Procesando respuesta exitosa del dispatch');
        // Feedback de éxito
          await AppSounds.success();
        
        if (!mounted) return;

        // Limpiar cualquier SnackBar existente y mostrar el nuevo
        scaffoldMessenger.hideCurrentSnackBar();
        
          // Mostrar mensaje del backend
                        final serverMessage = response.messageDetail ?? '';
                        final baseMessage = 'Guías actualizadas a estado "Listo para Entrega"';

                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                serverMessage.isNotEmpty
                                  ? '$serverMessage\n$baseMessage'
                                  : '${selectedGuides.length} $baseMessage',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            backgroundColor: Colors.green,
                            duration: serverMessage.isNotEmpty
                                ? const Duration(seconds: 10)
                                : const Duration(seconds: 4),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(8),
                          ),
                        );

        // Limpiar selección y quitar de la lista actual las guías despachadas
        final dispatchedSet = selectedGuides.toSet();
        provider.clearSelectedGuides();
        // Remover visualmente las guías ya despachadas de la lista actual
        final remaining = provider.guides.where((g) => !dispatchedSet.contains(g.code)).toList();
        provider.setGuides(remaining);
      } else {
        // Feedback de error
        HapticFeedback.heavyImpact();
          await AppSounds.error();
        final errorMessage = response.messageDetail ?? '';
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 10),
        ));
      }
    } catch (e) {
      if (!mounted) return;
          await AppSounds.error();
      scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Error procesando las guías'),
        backgroundColor: Colors.red,
      ));
    }
  }

  /// Maneja la entrada de guías individuales
  Future<void> _handleGuideInput(String? guide, GuideProvider provider) async {
    // Capture messenger before awaits to avoid context across async gaps
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (guide == null || guide.isEmpty) return;

    final cleanGuide = guide.trim();
    if (cleanGuide.isEmpty) return;

    // Ya no exigimos subcourier al escanear; se valida al procesar

    await _scanController.processScan(() async {
      try {
        // Buscar primero en la lista actual
        final currentGuides = provider.guides;
        final localMatch = currentGuides
            .where((g) => g.code == cleanGuide)
            .toList();

        // Si la guía ya está en la lista, usarla sin validar subcourier aquí
        if (localMatch.isNotEmpty) {
          await AppSounds.success();
          provider.updateGuideUiState(cleanGuide, 'scanned');
          if (!provider.isGuideSelected(cleanGuide)) {
            provider.toggleGuideSelection(cleanGuide);
          }
          if (!mounted) return;
          _controller.clear();
          return;
        }

        // Si no está en la lista, buscar en el backend usando searchQuery
        final selectedState = context.read<GuideProvider>().clientDispatchFilterState;
        final response = await provider.searchGuide(
          cleanGuide,
          status: selectedState,  // Usar solo el estado actualmente seleccionado
        );

        final exactMatch = response.content;
        
        if (exactMatch != null) {
          // No validar subcourier aquí, se hará al procesar
          await AppSounds.success();
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
          if (!mounted) return;
          await AppSounds.error();
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                response.messageDetail ?? '',
                style: const TextStyle(fontSize: 13, color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }

        if (!mounted) return;
        _controller.clear();
        // Mantener el foco
        Future.microtask(() {
          if (!_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
        });
      } catch (e) {
        if (!mounted) return;
        await AppSounds.error();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Error al procesar la guía'),
            backgroundColor: Colors.red,
          ),
        );
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

    // Asegurar que siempre tenemos el foco
    Future.microtask(() {
      if (!_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });

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
              color: theme.colorScheme.primary.withValues(alpha: 128),
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
