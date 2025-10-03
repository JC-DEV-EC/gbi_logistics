import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/scan_controller.dart';
import '../../providers/guide_validation_provider.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

/// Widget para escaneo y validación de guías
class GuideValidationScanBox extends StatefulWidget {
  final int? selectedSubcourierId;
  final String? selectedClientId;
  final void Function(String) onGuideValidated;

  const GuideValidationScanBox({
    super.key,
    this.selectedSubcourierId,
    this.selectedClientId,
    required this.onGuideValidated,
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

      // Capturar messenger antes de los awaits para evitar usar context tras async gaps
      final messenger = ScaffoldMessenger.of(context);
      final provider = context.read<GuideValidationProvider>();
      final response = await provider.validateGuideForCube(
        guideCode: cleanGuide,
        subcourierId: widget.selectedSubcourierId,
        clientId: widget.selectedClientId,
      );

      if (!mounted) return;

      // Reproducir sonido según resultado
      if (response.isSuccessful) {
        SystemSound.play(SystemSoundType.click);
        widget.onGuideValidated(cleanGuide);
      } else {
        await SystemSound.play(SystemSoundType.alert);
      }

      // Limpiar input
      _controller.clear();
      
      // Mostrar mensaje del backend
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            response.messageDetail ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: response.isSuccessful ? Colors.green : Colors.red,
          duration: Duration(seconds: response.isSuccessful ? 3 : 6),
        ),
      );
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
        decoration: InputDecoration(
          hintText: 'Escanee o ingrese el código de la guía',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: InputBorder.none,
          suffixIcon: Icon(
            Icons.qr_code_scanner,
            color: theme.colorScheme.primary.withValues(alpha: 128),
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