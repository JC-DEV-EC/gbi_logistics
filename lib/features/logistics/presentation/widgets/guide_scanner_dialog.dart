import 'package:flutter/material.dart';
import '../constants/visual_states.dart';

/// Widget para escanear guías con verificación
class GuideScannerDialog extends StatefulWidget {
  final String currentState;
  final int cubeId;
  final List<String> expectedGuides;
  final Function(List<String>) onComplete;

  const GuideScannerDialog({
    super.key,
    required this.currentState,
    required this.cubeId,
    required this.expectedGuides,
    required this.onComplete,
  });

  @override
  State<GuideScannerDialog> createState() => _GuideScannerDialogState();
}

class _GuideScannerDialogState extends State<GuideScannerDialog> {
  final List<String> _scannedGuides = [];
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleGuideScanned(String guide) {
    if (guide.isEmpty) return;

    if (!widget.expectedGuides.contains(guide)) {
      _showError('Guía no pertenece a este cubo');
      return;
    }

    if (_scannedGuides.contains(guide)) {
      _showWarning(
          'Guía ya ${widget.currentState == VisualStates.sent ? 'verificada' : 'descargada'}');
      return;
    }

    setState(() {
      _scannedGuides.add(guide);
    });

    _showSuccess(
        VisualStates.getGuideSuccessMessage(widget.currentState));

    if (_scannedGuides.length == widget.expectedGuides.length) {
      Navigator.pop(context);
      widget.onComplete(_scannedGuides);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showWarning(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actionLabel =
    widget.currentState == VisualStates.sent ? 'verificada' : 'descargada';

    return AlertDialog(
      title: Text(
          '${VisualStates.getGuideDialogTitle(widget.currentState)} - Cubo #${widget.cubeId}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Guías $actionLabel: ${_scannedGuides.length}/${widget.expectedGuides.length}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            focusNode: _focusNode,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Escanear guía',
              hintText: 'Escanee el código de la guía',
              prefixIcon: Icon(
                widget.currentState == VisualStates.sent
                    ? Icons.verified_outlined
                    : Icons.downloading,
              ),
            ),
            onChanged: (value) {
              // Handle newlines in onChanged
              if (value.endsWith('\n')) {
                _handleGuideScanned(value.replaceAll('\n', ''));
              }
            },
            onSubmitted: _handleGuideScanned,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
