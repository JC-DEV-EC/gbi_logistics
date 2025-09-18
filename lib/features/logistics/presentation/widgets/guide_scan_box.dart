import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/guide_provider.dart';
import '../controllers/scan_controller.dart';
import '../../services/app_sounds.dart';

/// Widget minimalista para escaneo de guías
class GuideScanBox extends StatefulWidget {
  final List<String> expectedGuides;
  final Function(List<String>) onComplete;
  final void Function(List<String>)? onChanged;
  final String? searchStatus;

  const GuideScanBox({
    super.key,
    required this.expectedGuides,
    required this.onComplete,
    this.onChanged,
    this.searchStatus,
  });

  @override
  State<GuideScanBox> createState() => _GuideScanBoxState();
}

class _GuideScanBoxState extends State<GuideScanBox> {
  final TextEditingController _controller = TextEditingController();
  final Set<String> _scannedGuides = {};
  bool _canComplete = false;
  final FocusNode _focusNode = FocusNode();
  final ScanController _scanController = ScanController();

  void _complete() {
    if (_canComplete) {
      widget.onComplete(_scannedGuides.toList());
      // Limpiar la lista después de validar
      setState(() {
        _scannedGuides.clear();
        _canComplete = false;
      });
      // Mantener el foco después de completar
      Future.microtask(() {
        if (!_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        // Campo de entrada
        Container(
          decoration: BoxDecoration(
            border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Escanee o ingrese el código de la guía',
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              border: InputBorder.none,
              suffixIcon: Icon(
                Icons.qr_code_scanner,
                color: theme.colorScheme.primary,
              ),
            ),
            onChanged: (value) {
              if (value.endsWith('\\n')) {
                _handleGuideInput(value.replaceAll('\\n', ''));
              }
            },
            onSubmitted: _handleGuideInput,
          ),
        ),

        const SizedBox(height: 16),

        // Botón de completar
        FilledButton.icon(
          onPressed: _scannedGuides.isNotEmpty ? _complete : null,
          icon: const Icon(Icons.done_all),
          label: Text(
            _scannedGuides.isEmpty
                ? 'Completar Verificación'
                : 'Completar (${_scannedGuides.length} guías)',
          ),
        ),

        if (_scannedGuides.isNotEmpty) ...[
          const SizedBox(height: 16),
          // Indicador de progreso
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Guías verificadas: ${_scannedGuides.length}/${widget
                    .expectedGuides.length}',
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Lista de guías escaneadas
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _scannedGuides.map((guide) {
                  return Chip(
                    label: Text(
                      guide,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: theme.colorScheme.primary,
                    deleteIcon: const Icon(
                        Icons.check, size: 18, color: Colors.white),
                    onDeleted: () {},
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }

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

  Future<void> _handleGuideInput(String? guide) async {
    if (guide == null || guide.isEmpty) return;

    final cleanGuide = guide.trim();
    if (cleanGuide.isEmpty) return;

    await _scanController.processScan(() async {
      try {
        // Si tiene searchStatus, buscar en servidor
        if (widget.searchStatus != null) {
          final provider = context.read<GuideProvider>();

          // Buscar la guía en el servidor
          final response = await provider.searchGuide(
            cleanGuide,
            status: widget.searchStatus!,
          );

          final result = response.content;

          if (result != null) {
            // La guía existe, verificar su estado
            if (result.stateLabel == widget.searchStatus) {
              // Solo agregar si no está validada
              final isValidated = provider.getGuideUiState(cleanGuide) ==
                  'validated';

              if (!isValidated) {
                setState(() {
                  _scannedGuides.add(cleanGuide);
                  _canComplete = _scannedGuides.isNotEmpty;
                });

                // Reproducir sonido de éxito
await AppSounds.success();

                // Notificar cambios
                widget.onChanged?.call(_scannedGuides.toList());
              } else {
                // Mostrar mensaje de que ya está validada
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'ℹ️ Guía $cleanGuide ya está validada para despacho'),
                    backgroundColor: Colors.blue,
                  ),
                );
              }

              _controller.clear();
            } else {
            // La guía existe pero está en otro estado
              HapticFeedback.heavyImpact();
await AppSounds.error();
              
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('⚠️ La guía $cleanGuide no puede ser procesada porque está en estado ${result.stateLabel}'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          } else {
            HapticFeedback.heavyImpact();
await AppSounds.error();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.messageDetail ?? response.message ?? 'Error al procesar guía'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          // Comportamiento original para otros estados
          if (widget.expectedGuides.contains(cleanGuide)) {
            setState(() {
              _scannedGuides.add(cleanGuide);
              _canComplete = _scannedGuides.isNotEmpty;
            });

            SystemSound.play(SystemSoundType.click);
            widget.onChanged?.call(_scannedGuides.toList());

            _controller.clear();
          } else if (cleanGuide.length >= 9) {
            HapticFeedback.heavyImpact();
          }
        }
      } catch (e) {
        if (mounted) {
await AppSounds.error();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error al procesar guía: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        _controller.clear();
        // Mantener el foco después de procesar cada guía
        Future.microtask(() {
          if (!_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
        });
      }
    });
  }

}