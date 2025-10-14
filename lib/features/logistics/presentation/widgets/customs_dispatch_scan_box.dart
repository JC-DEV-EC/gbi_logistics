import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/scan_controller.dart';
import '../../models/validate_guide_models.dart';
import '../../providers/guide_validation_provider.dart';
import '../helpers/error_helper.dart';
/*import '../../services/app_sounds.dart';*/

/// Widget para escaneo de guías en despacho en aduana
class CustomsDispatchScanBox extends StatefulWidget {
  final Function(List<String>, bool createCube) onComplete;

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

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildScanField(theme),
          if (_scannedGuides.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildCreateCubeButton(),
            const SizedBox(height: 16),
            _buildGuidesList(),
          ],
        ],
      ),
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
        decoration: InputDecoration(
          hintText: 'Escanee o ingrese el código de la guía',
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 400),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        shrinkWrap: true,
        itemCount: _scannedGuides.length,
        itemBuilder: (context, index) {
          final guide = _scannedGuides[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildGuideCard(guide),
          );
        },
      ),
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

    await _scanController.processScan(() async {
      try {
        final validationProvider = context.read<GuideValidationProvider>();
        final req = ValidateGuideStatusByProcessRequest(
          guideCode: cleanGuide,
          processInformation: ValidateGuideProcessType.toRegisterCube,
        );
        
        final resp = await validationProvider.validateGuideStatusByProcess(req);
        
        if (resp.isSuccessful && (resp.content?.isValid ?? false)) {
          setState(() {
            // Insertar al inicio para que la guía más reciente aparezca primero
            _scannedGuides.insert(0, cleanGuide);
          });
          /*await AppSounds.success();*/
          
          if (!mounted) return;
          if (resp.message?.isNotEmpty ?? false) {
            MessageHelper.showIconSnackBar(
              context,
              message: resp.message!,
              isSuccess: true,
            );
          }
        } else {
          /*await AppSounds.error();*/
          if (!mounted) return;
          
          MessageHelper.showIconSnackBar(
            context,
            message: resp.messageDetail ?? '',
            isSuccess: false,
          );
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
      }
    });
  }

  Future<void> _complete({required bool createCube}) async {
    if (_scannedGuides.isEmpty) return;

    final guides = List<String>.from(_scannedGuides);
    widget.onComplete(guides, createCube);

    setState(() {
      _scannedGuides.clear();
    });

    Future.microtask(() {
      if (!_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  void _removeGuide(String guide) {
    setState(() {
      _scannedGuides.remove(guide);
    });
  }
}