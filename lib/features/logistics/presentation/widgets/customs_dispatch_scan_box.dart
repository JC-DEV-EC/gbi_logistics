import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/scan_controller.dart';
import '../../models/validate_guide_models.dart';
import '../../providers/guide_validation_provider.dart';
import '../helpers/error_helper.dart';
import '../../services/native_sound_service.dart';

/// Widget para escaneo de guías en despacho en aduana
class CustomsDispatchScanBox extends StatefulWidget {
  final Future<bool> Function(List<String>, bool createCube) onComplete;

  const CustomsDispatchScanBox({
    super.key,
    required this.onComplete,
  });

  @override
  State<CustomsDispatchScanBox> createState() => _CustomsDispatchScanBoxState();
}

class _CustomsDispatchScanBoxState extends State<CustomsDispatchScanBox> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScanController _scanController = ScanController();
  final List<String> _scannedGuides = [];
  bool _isBlocked = false; // Bloquea el scanner cuando hay error

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scanController.dispose();
    super.dispose();
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildScanField(theme),
        if (_scannedGuides.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildCreateCubeButton(),
          const SizedBox(height: 16),
          Expanded(child: _buildGuidesList()),
        ],
      ],
    );
  }

  Widget _buildScanField(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 128)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: true,
        enabled: !_isBlocked, // Deshabilitar cuando está bloqueado
        decoration: InputDecoration(
          hintText: _isBlocked 
              ? 'Presione Continuar en el diálogo de error'
              : 'Escanee o ingrese el código de la guía',
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
          suffixIcon: Icon(
            Icons.qr_code_scanner,
            color: _isBlocked 
                ? theme.colorScheme.outline
                : theme.colorScheme.primary.withValues(alpha: 128),
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

  Widget _buildCreateCubeButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => _complete(createCube: true),
        icon: const Icon(Icons.add_box),
        label: Text('Crear Cubo (${_scannedGuides.length} guías)'),
      ),
    );
  }

  Widget _buildGuidesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _scannedGuides.length,
      itemBuilder: (context, index) {
        final guide = _scannedGuides[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildGuideCard(guide),
        );
      },
    );
  }

  Widget _buildGuideCard(String guide) {
    return ListTile(
      leading: const Icon(Icons.inventory_2_outlined),
      title: Text(guide),
      trailing: IconButton(
        icon: const Icon(Icons.remove_circle_outline),
        color: Colors.red,
        onPressed: () => _removeGuide(guide),
      ),
    );
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
    
    // Verificar si la guía ya fue escaneada
    if (_scannedGuides.contains(cleanGuide)) {
      MessageHelper.showIconSnackBar(
        context,
        message: 'Esta guía ya fue agregada',
        isSuccess: false,
      );
      _controller.clear();
      _focusNode.requestFocus();
      return;
    }

    await _scanController.processScan(() async {
      try {
        final validationProvider = context.read<GuideValidationProvider>();
        final req = ValidateGuideStatusByProcessRequest(
          guideCode: cleanGuide,
          processInformation: ValidateGuideProcessType.toRegisterCube,
        );
        
        final resp = await validationProvider.validateGuideStatusByProcess(req);
        
        if (resp.isSuccessful && (resp.content?.isValid ?? false)) {
          if (!mounted) return;
          
          // Si hay userMessage (no null y no vacío), mostrar diálogo bloqueante ANTES de agregar la guía
          final userMessage = resp.content?.userMessage;
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
          setState(() {
            // Insertar al inicio para que la guía más reciente aparezca primero
            _scannedGuides.insert(0, cleanGuide);
          });
          
          if (!mounted) return;
          
          // Mostrar mensaje de éxito normal solo si NO había userMessage
          if ((userMessage == null || userMessage.isEmpty) && (resp.message?.isNotEmpty ?? false)) {
            MessageHelper.showIconSnackBar(
              context,
              message: resp.message!,
              isSuccess: true,
              successDuration: const Duration(milliseconds: 500),
            );
          }
        } else {
          // Sonido de error nativo del sistema
          NativeSoundService.playErrorSound();
          
          // Bloquear el scanner
          setState(() {
            _isBlocked = true;
          });
          
          // Mostrar diálogo bloqueante de error
          await MessageHelper.showBlockingErrorDialog(
            context,
            resp.messageDetail ?? 'Error al validar la guía',
          );
          
          // Desbloquear el scanner después de cerrar el diálogo
          if (mounted) {
            setState(() {
              _isBlocked = false;
            });
          }
        }
      } finally {
        if (mounted) {
          _controller.clear();
          Future.microtask(() {
            if (!_focusNode.hasFocus) {
              _focusNode.requestFocus();
            }
          });
        }
        
        // Log de fin de escaneo
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime).inMilliseconds;
        print('[SCAN-TIMER] Fin escaneo de guía: $cleanGuide - Duración: ${duration}ms');
      }
    });
  }

  Future<void> _complete({required bool createCube}) async {
    if (_scannedGuides.isEmpty) return;

    final guides = List<String>.from(_scannedGuides);
    // Llamar al callback y esperar el resultado
    final success = await widget.onComplete(guides, createCube);

    // Solo limpiar las guías si fue exitoso
    if (success && mounted) {
      setState(() {
        _scannedGuides.clear();
      });
    }

    if (mounted) {
      Future.microtask(() {
        if (!_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  void _removeGuide(String guide) {
    setState(() {
      _scannedGuides.remove(guide);
    });
  }
}