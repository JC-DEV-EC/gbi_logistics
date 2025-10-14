import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/scan_controller.dart';
import '../../providers/guide_validation_provider.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../helpers/error_helper.dart';

/// Widget para escaneo y validación de guías
class GuideValidationScanBox extends StatefulWidget {
  final int? selectedSubcourierId;
  final String? selectedClientId;
  final void Function(String) onGuideValidated;
  final bool requiresClient;

  const GuideValidationScanBox({
    super.key,
    this.selectedSubcourierId,
    this.selectedClientId,
    required this.onGuideValidated,
    this.requiresClient = false,
  });

  @override
  State<GuideValidationScanBox> createState() => _GuideValidationScanBoxState();
}

class _GuideValidationScanBoxState extends State<GuideValidationScanBox> {
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

  Future<void> _handleGuideInput(String? guide) async {
    if (guide == null || guide.isEmpty) return;

    final cleanGuide = guide.trim();
    if (cleanGuide.isEmpty) return;

    // Usar el controlador de escaneo para procesar la guía
    await _scanController.processScan(() async {
      // Refrescar token primero
      final authProvider = context.read<AuthProvider>();
      await authProvider.ensureFreshToken();

      if (!mounted) return;

      final provider = context.read<GuideValidationProvider>();
      final response = await provider.validateGuideForCube(
        guideCode: cleanGuide,
        subcourierId: widget.selectedSubcourierId,
        clientId: widget.selectedClientId,
      );

      if (!mounted) return;

      // El provider retorna ApiResponse<void>, por lo que no hay content. Usar solo el flag de éxito del backend
      final isValid = response.isSuccessful;

      // Reproducir sonido según resultado
      if (isValid) {
        SystemSound.play(SystemSoundType.click);
        widget.onGuideValidated(cleanGuide);
      } else {
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.heavyImpact();
      }

      // Mostrar mensaje del backend
      final message = isValid 
          ? (response.message ?? '')
          : (response.messageDetail ?? '');
      
      if (message.isNotEmpty) {
        MessageHelper.showIconSnackBar(
          context,
          message: message,
          isSuccess: isValid,
        );
      }

      // Limpiar input
      _controller.clear();
    });
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

    return Container(
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
        enabled: widget.selectedSubcourierId != null && 
                (!widget.requiresClient || widget.selectedClientId != null),
        decoration: InputDecoration(
          hintText: widget.selectedSubcourierId == null
              ? 'Seleccione un subcourier para habilitar el escaneo'
              : (widget.requiresClient && widget.selectedClientId == null
                  ? 'Seleccione un cliente para continuar'
                  : 'Escanee o ingrese el código de la guía'),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: InputBorder.none,
          suffixIcon: Icon(
            Icons.qr_code_scanner,
            color: widget.selectedSubcourierId != null
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
        ),
        onChanged: (value) {
          if (value.endsWith('\n')) {
            _handleGuideInput(value.replaceAll('\n', ''));
          }
        },
        onSubmitted: _handleGuideInput,
      ),
    );
  }
}