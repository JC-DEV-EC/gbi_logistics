import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../presentation/controllers/scan_controller.dart';

/// Widget de scanner específico para la pantalla de detalles de guía
class GuideDetailsScannerWidget extends StatefulWidget {
  final Function(String) onCodeScanned;

  const GuideDetailsScannerWidget({
    super.key,
    required this.onCodeScanned,
  });

  @override
  State<GuideDetailsScannerWidget> createState() => _GuideDetailsScannerWidgetState();
}

class _GuideDetailsScannerWidgetState extends State<GuideDetailsScannerWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScanController _scanController = ScanController();
  bool _isProcessing = false;

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

  String? _lastProcessedCode;

  Future<void> _handleGuideInput(String? guide) async {
    if (guide == null || guide.isEmpty || _isProcessing) return;
    
    final cleanGuide = guide.trim();
    if (cleanGuide.isEmpty) return;

    // Evitar procesar el mismo código múltiples veces
    if (_lastProcessedCode == cleanGuide) {
      _controller.clear();
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      _lastProcessedCode = cleanGuide;
      await _scanController.processScan(() async {
        // Vibración de feedback
        await HapticFeedback.lightImpact();
        
        // Limpiar el campo
        _controller.clear();
        
        // Notificar el código escaneado
        widget.onCodeScanned(cleanGuide);
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
      
      // Mantener el foco para el siguiente escaneo
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
      children: [
        // Ícono de escaneo
        Icon(
          Icons.qr_code_scanner,
          size: 48,
          color: theme.colorScheme.primary.withValues(alpha: 128),
        ),
        const SizedBox(height: 16),
        
        // Campo de entrada
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 128),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: !_isProcessing,
                autofocus: true,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Escanee o ingrese el código de la guía',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  if (value.endsWith('\n')) {
                    _handleGuideInput(value.replaceAll('\n', ''));
                  }
                },
                onSubmitted: _handleGuideInput,
              ),
              if (_isProcessing)
                Positioned.fill(
                  child: Container(
                    color: theme.colorScheme.surface.withValues(alpha: 204),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}