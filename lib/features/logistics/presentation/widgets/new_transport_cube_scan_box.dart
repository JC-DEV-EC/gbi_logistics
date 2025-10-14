import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/validate_guide_models.dart';
import '../../providers/guide_validation_provider.dart';
import '../../services/app_sounds.dart';
import '../controllers/scan_controller.dart';

/// Widget para escaneo de guías en nuevo cubo de transporte
class NewTransportCubeScanBox extends StatefulWidget {
  final Function(List<String>) onComplete;

  const NewTransportCubeScanBox({
    super.key,
    required this.onComplete,
  });

  @override
  State<NewTransportCubeScanBox> createState() => _NewTransportCubeScanBoxState();
}

class _NewTransportCubeScanBoxState extends State<NewTransportCubeScanBox> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScanController _scanController = ScanController();
  final Set<String> _scannedGuides = {};

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
            _scannedGuides.add(cleanGuide);
          });
          await AppSounds.success();
          
          if (!mounted) return;
          if (resp.message?.isNotEmpty ?? false) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(resp.message!),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          
          // Notificar guías actualizadas
          widget.onComplete(_scannedGuides.toList());
        } else {
          await AppSounds.error();
          if (!mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resp.messageDetail ?? ''),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
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

  void _removeGuide(String guide) {
    setState(() {
      _scannedGuides.remove(guide);
    });
    widget.onComplete(_scannedGuides.toList());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Campo de escaneo
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.5),
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
                _handleGuideInput(value.replaceAll('\n', ''));
              }
            },
            onSubmitted: _handleGuideInput,
          ),
        ),

        // Lista de guías escaneadas
        if (_scannedGuides.isNotEmpty) ...[
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _scannedGuides.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final guide = _scannedGuides.elementAt(index);
              return ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(guide),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => _removeGuide(guide),
                  color: Colors.red,
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}