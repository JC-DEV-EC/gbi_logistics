import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/guide_provider.dart';
import '../controllers/scan_controller.dart';
/*import '../../services/app_sounds.dart';*/
import '../helpers/error_helper.dart';

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
  // Controllers
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScanController _scanController = ScanController();

  // Estado interno
  final Set<String> _scannedGuides = {};
  bool _canComplete = false;

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

  /// Completa el proceso y ejecuta callback con las guías escaneadas
  Future<void> _complete() async {
    if (_canComplete && _scannedGuides.isNotEmpty) {
      final guides = _scannedGuides.toList();
      widget.onComplete(guides);

      setState(() {
        _scannedGuides.clear();
        _canComplete = false;
      });

      Future.microtask(() {
        if (!_focusNode.hasFocus) _focusNode.requestFocus();
      });
    }
  }

  /// Procesa el ingreso de una guía
  Future<void> _handleGuideInput(String? guide) async {
    if (guide == null || guide.isEmpty) return;
    final cleanGuide = guide.trim();
    if (cleanGuide.isEmpty) return;

    await _scanController.processScan(() async {
      try {
        if (widget.searchStatus != null) {
          // Con validación contra el backend
          final provider = context.read<GuideProvider>();
          final guideProvider = provider;
          final response = await provider.searchGuide(
            cleanGuide,
            status: widget.searchStatus!,
          );

          final result = response.content;
          if (result != null) {
            if (result.stateLabel == widget.searchStatus) {
              final isValidated = guideProvider.getGuideUiState(cleanGuide) == 'validated';

              if (!isValidated) {
                setState(() {
                  _scannedGuides.add(cleanGuide);
                  _canComplete = _scannedGuides.isNotEmpty;
                });
                /*await AppSounds.success();*/
                widget.onChanged?.call(_scannedGuides.toList());
              } else {
              MessageHelper.showIconSnackBar(
                context,
                message: response.messageDetail ?? '',
                isSuccess: true,
              );
              }
              _controller.clear();
            } else {
              HapticFeedback.heavyImpact();
              /*await AppSounds.error();*/

              if (!mounted) return;
              MessageHelper.showIconSnackBar(
                context,
                message: response.messageDetail ?? '',
                isSuccess: false,
              );
            }
          } else {
            HapticFeedback.heavyImpact();
            /*await AppSounds.error();*/

            if (!mounted) return;
              MessageHelper.showIconSnackBar(
                context,
                message: response.messageDetail ?? '',
                isSuccess: false,
              );
          }
        } else {
          // Sin validación contra backend, solo expectedGuides
          if (widget.expectedGuides.contains(cleanGuide)) {
            setState(() {
              _scannedGuides.add(cleanGuide);
              _canComplete = _scannedGuides.isNotEmpty;
            });

            SystemSound.play(SystemSoundType.click);
            widget.onChanged?.call(_scannedGuides.toList());
          } else if (cleanGuide.length >= 9) {
            HapticFeedback.heavyImpact();
            /*await AppSounds.error();*/
          }
        }
      } catch (_) {
        if (mounted) {
          /*await AppSounds.error();*/
          // No mostrar mensajes locales; el backend debe proveer messageDetail
        }
      } finally {
        _controller.clear();
        Future.microtask(() {
          if (!_focusNode.hasFocus) _focusNode.requestFocus();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Mantener foco
    Future.microtask(() {
      if (!_focusNode.hasFocus) _focusNode.requestFocus();
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Campo de entrada
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 128)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Escanee o ingrese el código de la guía',
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
              suffixIcon: Icon(
                Icons.qr_code_scanner,
                color: theme.colorScheme.primary.withValues(alpha: 128),
              ),
            ),
            onSubmitted: _handleGuideInput,
            onChanged: (value) {
              if (value.endsWith('\n')) {
                _handleGuideInput(value.replaceAll('\n', ''));
              }
            },
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

          // Resumen
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Guías verificadas: ${_scannedGuides.length}/${widget.expectedGuides.length}',
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Chips con guías escaneadas
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
                    deleteIcon: const Icon(Icons.check, size: 18, color: Colors.white),
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
}