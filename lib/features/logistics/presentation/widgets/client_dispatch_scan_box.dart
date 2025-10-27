import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:logiruta/core/services/app_logger.dart';

import '../../models/operation_models.dart';
import '../../models/validate_guide_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/guide_validation_provider.dart';
import '../../providers/guide_provider.dart';
import '../controllers/scan_controller.dart';
import '../../services/guide_details_service.dart';
import '../helpers/error_helper.dart';
import '../../services/native_sound_service.dart';

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

  Future<void> _processBatchGuides(GuideProvider provider) async {
    if (!await _canProcessGuides(provider)) return;

    final stopwatch = Stopwatch()..start();
    AppLogger.log('[PERFORMANCE] Iniciando procesamiento por lotes', source: 'ClientDispatchScanBox');
    if (!mounted) return;

    final selectedGuides = provider.selectedGuides.toList();

    if (provider.selectedSubcourierId == null) {
      MessageHelper.showIconSnackBar(
        context,
        message: 'Por favor seleccione un subcourier',
        isSuccess: false,
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final selectedSub = auth.subcouriers.firstWhere((s) => s.id == provider.selectedSubcourierId);

    final currentGuides = provider.guides;
    final selectedGuideInfos = currentGuides.where((g) => selectedGuides.contains(g.code)).toList();

    final mismatches = selectedGuideInfos
        .where((g) => (g.subcourierName ?? '').trim() != (selectedSub.name ?? '').trim())
        .toList();

    if (mismatches.isNotEmpty) {
      final sample = mismatches.take(3).map((g) => g.code).join(', ');
      final extra = mismatches.length > 3 ? ' y ${mismatches.length - 3} más' : '';
      if (!mounted) return;

      MessageHelper.showIconSnackBar(
        context,
        message: 'Las guías $sample$extra pertenecen a otro subcourier',
        isSuccess: false,
      );
      return;
    }

    try {
      final request = DispatchGuideToClientRequest(
        subcourierId: provider.selectedSubcourierId!,
        guides: selectedGuides,
      );

      AppLogger.log('[PERFORMANCE] Iniciando dispatchToClient', source: 'ClientDispatchScanBox');
      final response = await provider.dispatchToClient(request);
      AppLogger.log('[PERFORMANCE] dispatchToClient completado en ${stopwatch.elapsedMilliseconds}ms', source: 'ClientDispatchScanBox');

      if (!mounted) return;

      // Debug log para ver el estado de la respuesta
      AppLogger.log('[DEBUG-RESPONSE] response.isSuccessful: ${response.isSuccessful}', source: 'ClientDispatchScanBox');
      AppLogger.log('[DEBUG-RESPONSE] response object: $response', source: 'ClientDispatchScanBox');

      if (response.isSuccessful) {
        // Debug log para ver qué mensaje llega
        AppLogger.log('[DEBUG-SUCCESS] response.message: "${response.message}"', source: 'ClientDispatchScanBox');
        AppLogger.log('[DEBUG-SUCCESS] response.messageDetail: "${response.messageDetail}"', source: 'ClientDispatchScanBox');

        // Mostrar mensaje de éxito del backend o mensaje por defecto
        final successMessage = (response.message ?? '').isNotEmpty
            ? response.message!
            : 'Guías despachadas exitosamente';
        AppLogger.log('[DEBUG-SUCCESS] successMessage to show: "$successMessage"', source: 'ClientDispatchScanBox');
        _showMessage(context, successMessage, false);

        final dispatchedSet = selectedGuides.toSet();
        provider.clearSelectedGuides();

        final remaining = provider.guides.where((g) => !dispatchedSet.contains(g.code)).toList();
        provider.setGuides(remaining);

        // Desbloquear selectores y resetear selecciones para permitir nuevo proceso
        provider.unlockSelectors();
        provider.resetSelections();
      } else {
        HapticFeedback.heavyImpact();
        final errorMessage = response.messageDetail ?? '';
        MessageHelper.showIconSnackBar(
          context,
          message: errorMessage,
          isSuccess: false,
        );
      }
    } catch (e) {
      if (!mounted) return;
    }
  }

  Future<bool> _canProcessGuides(GuideProvider provider) async {
    if (!mounted || provider.selectedGuides.isEmpty) return false;

    try {
      final validationProvider = context.read<GuideValidationProvider>();

      final firstGuide = provider.selectedGuides.first;

      final request = ValidateGuideStatusByProcessRequest(
        guideCode: firstGuide,
        subcourierId: provider.selectedSubcourierId,
        clientId: provider.selectedClientId,
        processInformation: ValidateGuideProcessType.toDispatchToClient,
      );

      final response = await validationProvider.validateGuideStatusByProcess(request);

      if (response.messageDetail != null && response.messageDetail!.isNotEmpty) {
        if (!mounted) return false;

        MessageHelper.showIconSnackBar(
          context,
          message: response.messageDetail!,
          isSuccess: false,
        );
        return false;
      }

      return true;
    } catch (e) {
      AppLogger.error('Error validando procesamiento', error: e, source: 'ClientDispatchScanBox');
      return false;
    }
  }

  void _showMessage(BuildContext context, String message, bool isError, [Duration? successDuration]) {
    MessageHelper.showIconSnackBar(
      context,
      message: message,
      isSuccess: !isError,
      successDuration: !isError ? successDuration : null,
    );
  }

  Future<void> _handleGuideInput(String? guide, GuideProvider provider) async {
    if (!mounted) return;

    final cleanGuide = guide?.trim() ?? '';
    if (cleanGuide.isEmpty) return;

    // Validar que se puedan realizar escaneos
    if (!provider.canStartScanning) {
      _controller.clear();
      return;
    }

    // No procesar si está bloqueado (evita que el scanner físico envíe datos)
    if (_isBlocked) return;

    await _scanController.processScan(() async {
      try {
        final detailsService = context.read<GuideDetailsService>();
        final detailsResponse = await detailsService.getGuideDetails(cleanGuide);

        if (detailsResponse.isSuccessful && detailsResponse.content != null) {
          final details = detailsResponse.content!;
          final selectedSubName = context
              .read<AuthProvider>()
              .subcouriers
              .firstWhere((s) => s.id == provider.selectedSubcourierId)
              .name ??
              '';

          if (details.subcourierName?.trim() != selectedSubName.trim()) {
            // Error de subcourier no coincidente - usar diálogo bloqueante
            NativeSoundService.playErrorSound();

            setState(() {
              _isBlocked = true;
            });

            await MessageHelper.showBlockingErrorDialog(
              context,
              'La guía pertenece a ${details.subcourierName}, no a $selectedSubName',
            );

            if (mounted) {
              setState(() {
                _isBlocked = false;
              });
            }
            _controller.clear();
            return;
          }

          // Validar estado de la guía ANTES de agregar a pantalla
          final validationProvider = context.read<GuideValidationProvider>();
          final validationRequest = ValidateGuideStatusByProcessRequest(
            guideCode: cleanGuide,
            subcourierId: provider.selectedSubcourierId,
            clientId: provider.selectedClientId,
            processInformation: ValidateGuideProcessType.toDispatchToClient,
          );

          final validationResponse = await validationProvider.validateGuideStatusByProcess(validationRequest);

          // Debug logs
          AppLogger.log('[DEBUG] validationResponse.isSuccessful: ${validationResponse.isSuccessful}', source: 'ClientDispatchScanBox');
          AppLogger.log('[DEBUG] validationResponse.content: ${validationResponse.content}', source: 'ClientDispatchScanBox');
          AppLogger.log('[DEBUG] validationResponse.content?.isValid: ${validationResponse.content?.isValid}', source: 'ClientDispatchScanBox');
          AppLogger.log('[DEBUG] validationResponse.messageDetail: ${validationResponse.messageDetail}', source: 'ClientDispatchScanBox');

          final isValidState = validationResponse.isSuccessful && validationResponse.content?.isValid == true;

          if (!isValidState) {
            // Sonido de error nativo del sistema
            NativeSoundService.playErrorSound();

            // Bloquear el scanner
            setState(() {
              _isBlocked = true;
            });

            // Mostrar diálogo bloqueante de error con messageDetail del backend
            await MessageHelper.showBlockingErrorDialog(
              context,
              validationResponse.messageDetail ?? '',
            );

            // Desbloquear el scanner después de cerrar el diálogo
            if (mounted) {
              setState(() {
                _isBlocked = false;
              });
            }
            _controller.clear();
            return;
          }

          provider.updateGuideUiState(cleanGuide, 'scanned');

          // Bloquear selectores después del primer escaneo exitoso
          if (!provider.selectorsLocked) {
            provider.lockSelectors();
          }

          if (!provider.guides.any((g) => g.code == details.guideCode)) {
            final guideInfo = GuideInfo(
              code: details.guideCode,
              subcourierName: details.subcourierName,
              packages: details.packages,
              stateLabel: details.stateLabel,
              updateDateTime: details.updateDateTime,
            );

            final newGuides = List<GuideInfo>.from(provider.guides);
            newGuides.insert(0, guideInfo);
            provider.setGuides(newGuides);
          }

          // Mostrar mensaje del backend si existe
          if (validationResponse.message?.isNotEmpty ?? false) {
            _showMessage(context, validationResponse.message!, false, const Duration(milliseconds: 500));
          }

          if (!provider.isGuideSelected(cleanGuide)) {
            provider.toggleGuideSelection(cleanGuide);
          }

          _controller.clear();
          return;
        }

        final validationProvider = context.read<GuideValidationProvider>();
        final validationRequest = ValidateGuideStatusByProcessRequest(
          guideCode: cleanGuide,
          subcourierId: provider.selectedSubcourierId,
          clientId: provider.selectedClientId,
          processInformation: ValidateGuideProcessType.toDispatchToClient,
        );

        final validationResponse = await validationProvider.validateGuideStatusByProcess(validationRequest);

        // Debug logs - segundo flujo
        AppLogger.log('[DEBUG-2] validationResponse.isSuccessful: ${validationResponse.isSuccessful}', source: 'ClientDispatchScanBox');
        AppLogger.log('[DEBUG-2] validationResponse.content: ${validationResponse.content}', source: 'ClientDispatchScanBox');
        AppLogger.log('[DEBUG-2] validationResponse.content?.isValid: ${validationResponse.content?.isValid}', source: 'ClientDispatchScanBox');
        AppLogger.log('[DEBUG-2] validationResponse.messageDetail: ${validationResponse.messageDetail}', source: 'ClientDispatchScanBox');

        final isValidState = validationResponse.isSuccessful && validationResponse.content?.isValid == true;

        if (!isValidState) {
          // Sonido de error nativo del sistema
          NativeSoundService.playErrorSound();

          // Bloquear el scanner
          setState(() {
            _isBlocked = true;
          });

          // Mostrar diálogo bloqueante de error con messageDetail del backend
          await MessageHelper.showBlockingErrorDialog(
            context,
            validationResponse.messageDetail ?? '',
          );

          // Desbloquear el scanner después de cerrar el diálogo
          if (mounted) {
            setState(() {
              _isBlocked = false;
            });
          }
          return;
        }

        final response = await provider.searchGuide(
          cleanGuide,
          status: TrackingStateType.receivedInLocalWarehouse,
        );

        final exactMatch = response.content;

        if (response.isSuccessful && exactMatch != null) {
          provider.updateGuideUiState(cleanGuide, 'scanned');
          
          // Bloquear selectores después del primer escaneo exitoso
          if (!provider.selectorsLocked) {
            provider.lockSelectors();
          }
          
          if (!provider.isGuideSelected(cleanGuide)) {
            provider.toggleGuideSelection(cleanGuide);
          }

          // Mostrar mensaje del backend si existe
          if ((response.message ?? '').isNotEmpty) {
            _showMessage(context, response.message!, false, const Duration(milliseconds: 500));
          }

          if (!provider.guides.any((g) => g.code == exactMatch.code)) {
            provider.setGuides([exactMatch, ...provider.guides]);
          }
        } else {
          // Sonido de error nativo del sistema
          NativeSoundService.playErrorSound();
          
          // Bloquear el scanner
          setState(() {
            _isBlocked = true;
          });
          
          // Mostrar diálogo bloqueante de error con messageDetail del backend
          await MessageHelper.showBlockingErrorDialog(
            context,
            response.messageDetail ?? '',
          );
          
          // Desbloquear el scanner después de cerrar el diálogo
          if (mounted) {
            setState(() {
              _isBlocked = false;
            });
          }
        }

        _controller.clear();

        Future.microtask(() {
          if (!_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
        });
      } catch (e) {
        // No mostrar mensajes locales, solo del backend
      } finally {
        _controller.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<GuideProvider>();

    if (!_focusNode.hasFocus && MediaQuery.of(context).viewInsets.bottom == 0) {
      Future.microtask(() => _focusNode.requestFocus());
    }

    Future.microtask(() {
      if (!_focusNode.hasFocus) _focusNode.requestFocus();
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (provider.selectedGuides.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: FilledButton.icon(
              onPressed: () => _processBatchGuides(provider),
              icon: const Icon(Icons.check_circle_outline),
              label: Text('Procesar ${provider.selectedGuides.length} guías'),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: provider.canStartScanning
                  ? theme.colorScheme.primary.withOpacity(0.5)
                  : theme.colorScheme.outline.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(8),
            color: provider.canStartScanning
                ? theme.colorScheme.surface
                : theme.colorScheme.surfaceVariant.withOpacity(0.3),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: provider.canStartScanning,
            enabled: provider.canStartScanning,
            decoration: InputDecoration(
              hintText: provider.canStartScanning 
                  ? 'Escanee o ingrese el código de la guía'
                  : 'Seleccione subcourier${provider.requiresClient ? ' y cliente' : ''} para escanear',
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
              suffixIcon: Icon(
                Icons.qr_code_scanner, 
                color: provider.canStartScanning 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
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
        const SizedBox(height: 16),
      ],
    );
  }
}
