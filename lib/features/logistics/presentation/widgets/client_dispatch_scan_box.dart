import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/operation_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/guide_provider.dart';
import '../../services/app_sounds.dart';
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
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (!mounted) return;

    final selectedGuides = provider.selectedGuides.toList();

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

    final auth = context.read<AuthProvider>();
    final selectedSub = auth.subcouriers.firstWhere(
          (s) => s.id == provider.selectedSubcourierId,
    );

    final currentGuides = provider.guides;
    final selectedGuideInfos = currentGuides
        .where((g) => selectedGuides.contains(g.code))
        .toList();

    final mismatches = selectedGuideInfos
        .where((g) =>
    (g.subcourierName ?? '').trim() != (selectedSub.name ?? '').trim())
        .toList();

    if (mismatches.isNotEmpty) {
      final sample = mismatches.take(3).map((g) => g.code).join(', ');
      final extra =
      mismatches.length > 3 ? ' y ${mismatches.length - 3} más' : '';
      if (!mounted) return;

      await AppSounds.error();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content:
          Text('Las guías $sample$extra pertenecen a otro subcourier'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    try {
      final request = DispatchGuideToClientRequest(
        subcourierId: provider.selectedSubcourierId!,
        guides: selectedGuides,
      );

      final response = await provider.dispatchToClient(request);
      if (!mounted) return;

      if (response.isSuccessful) {
        await AppSounds.success();
        if (!mounted) return;
        
        if ((response.message ?? '').isNotEmpty) {
          _showMessage(context, response.message!, false);
        }

        final dispatchedSet = selectedGuides.toSet();
        provider.clearSelectedGuides();

        final remaining = provider.guides
            .where((g) => !dispatchedSet.contains(g.code))
            .toList();
        provider.setGuides(remaining);
      } else {
        HapticFeedback.heavyImpact();
        await AppSounds.error();
        final errorMessage = response.messageDetail ?? '';
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      await AppSounds.error();
    }
  }

  /// Maneja la entrada de guías individuales
  void _showMessage(BuildContext context, String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 14),
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
      ),
    );
  }

  Future<void> _handleGuideInput(String? guide, GuideProvider provider) async {
    if (!mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (guide == null || guide.isEmpty) return;

    final cleanGuide = guide.trim();
    if (cleanGuide.isEmpty) return;

    await _scanController.processScan(() async {
      try {
        final currentGuides = provider.guides;
        final localMatch =
        currentGuides.where((g) => g.code == cleanGuide).toList();

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

        final selectedState = context
            .read<GuideProvider>()
            .clientDispatchFilterState;
        final response = await provider.searchGuide(
          cleanGuide,
          status: selectedState,
        );

        final exactMatch = response.content;

        if (response.isSuccessful && exactMatch != null) {
          await AppSounds.success();
          provider.updateGuideUiState(cleanGuide, 'scanned');
          if (!provider.isGuideSelected(cleanGuide)) {
            provider.toggleGuideSelection(cleanGuide);
          }
          
          if (!mounted) return;
          if ((response.message ?? '').isNotEmpty) {
            _showMessage(context, response.message!, false);
          }

          final newGuides = List<GuideInfo>.from(currentGuides);
          newGuides.insert(0, exactMatch);
          provider.setGuides(newGuides);
        } else {
          HapticFeedback.heavyImpact();
          if (!mounted) return;
          await AppSounds.error();
          if (!mounted) return;
          _showMessage(context, response.messageDetail ?? '', true);
        }

        if (!mounted) return;
        _controller.clear();

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

    if (!_focusNode.hasFocus &&
        MediaQuery.of(context).viewInsets.bottom == 0) {
      Future.microtask(() => _focusNode.requestFocus());
    }

    Future.microtask(() {
      if (!_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
