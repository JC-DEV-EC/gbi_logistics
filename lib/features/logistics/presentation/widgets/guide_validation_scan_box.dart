import 'package:flutter/material.dart';
import '../controllers/scan_controller.dart';
import '../../providers/guide_validation_provider.dart';
import '../../models/validate_guide_models.dart';
import 'package:provider/provider.dart';
import '../helpers/error_helper.dart';
import '../../services/native_sound_service.dart';

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
  final Set<String> _alreadyValidatedGuides = {};
  bool _isBlocked = false; // Bloquea el scanner cuando hay error

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
    
    // No procesar si está bloqueado (evita que el scanner físico envíe datos)
    if (_isBlocked) return;
    
    // Log de inicio de escaneo
    final startTime = DateTime.now();
    print('[SCAN-TIMER] Inicio escaneo de guía: $cleanGuide');

    // Verificar si la guía ya fue validada
    if (_alreadyValidatedGuides.contains(cleanGuide)) {
      MessageHelper.showIconSnackBar(
        context,
        message: 'Esta guía ya fue agregada',
        isSuccess: false,
      );
      _controller.clear();
      _focusNode.requestFocus();
      return;
    }

    // Usar el controlador de escaneo para procesar la guía
    await _scanController.processScan(() async {
      if (!mounted) return;

      final provider = context.read<GuideValidationProvider>();
      final request = ValidateGuideStatusByProcessRequest(
        guideCode: cleanGuide,
        subcourierId: widget.selectedSubcourierId,
        clientId: widget.selectedClientId,
        processInformation: ValidateGuideProcessType.toRegisterCubeToDispatch,
      );
      
      final response = await provider.validateGuideStatusByProcess(request);

      if (!mounted) return;

      // Verificar si la guía es válida
      final isValid = response.isSuccessful && (response.content?.isValid ?? false);

      if (isValid) {
        // Si hay userMessage (no null y no vacío), mostrar diálogo bloqueante ANTES de agregar la guía
        final userMessage = response.content?.userMessage;
        if (userMessage != null && userMessage.isNotEmpty) {
          // Sonido de error
          NativeSoundService.playErrorSound();
          
          // Bloquear el scanner
          setState(() {
            _isBlocked = true;
          });
          
          // Mostrar diálogo bloqueante amarillo con userMessage
          await MessageHelper.showBlockingWarningDialog(
            context,
            userMessage,
          );
          
          // Desbloquear el scanner después de cerrar el diálogo
          if (mounted) {
            setState(() {
              _isBlocked = false;
            });
          }
        }
        
        // Agregar la guía DESPUÉS de mostrar el mensaje (si había)
        _alreadyValidatedGuides.add(cleanGuide);
        widget.onGuideValidated(cleanGuide);
        
        // Mostrar mensaje de éxito solo si NO había userMessage
        if (userMessage == null || userMessage.isEmpty) {
          final message = response.message ?? '';
          if (message.isNotEmpty) {
            MessageHelper.showIconSnackBar(
              context,
              message: message,
              isSuccess: true,
              successDuration: const Duration(milliseconds: 500),
            );
          }
        }
      } else {
        // Sonido de error nativo del sistema
        NativeSoundService.playErrorSound();
        
        // Bloquear el scanner
        setState(() {
          _isBlocked = true;
        });
        
        // Mostrar diálogo bloqueante de error
        final errorMessage = response.messageDetail ?? 'Error al validar la guía';
        await MessageHelper.showBlockingErrorDialog(context, errorMessage);
        
        // Desbloquear el scanner después de cerrar el diálogo
        if (mounted) {
          setState(() {
            _isBlocked = false;
          });
        }
      }

      // Limpiar input
      _controller.clear();
      
      // Log de fin de escaneo
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;
      print('[SCAN-TIMER] Fin escaneo de guía: $cleanGuide - Duración: ${duration}ms');
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
        enabled: !_isBlocked &&
                widget.selectedSubcourierId != null && 
                (!widget.requiresClient || widget.selectedClientId != null),
        decoration: InputDecoration(
          hintText: _isBlocked
              ? 'Presione Continuar en el diálogo de error'
              : (widget.selectedSubcourierId == null
                  ? 'Seleccione un subcourier para habilitar el escaneo'
                  : (widget.requiresClient && widget.selectedClientId == null
                      ? 'Seleccione un cliente para continuar'
                      : 'Escanee o ingrese el código de la guía')),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: InputBorder.none,
          suffixIcon: Icon(
            Icons.qr_code_scanner,
            color: _isBlocked || widget.selectedSubcourierId == null
                ? theme.colorScheme.outline
                : theme.colorScheme.primary,
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