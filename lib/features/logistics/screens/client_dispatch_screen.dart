import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/auth_models.dart';
import '../providers/auth_provider.dart';
import '../providers/guide_provider.dart';
import '../presentation/widgets/app_drawer.dart';
import '../presentation/widgets/client_dispatch_list_screen.dart';
import '../presentation/widgets/client_dispatch_scan_box.dart';

/// Pantalla para despacho a cliente
class ClientDispatchScreen extends StatefulWidget {
  const ClientDispatchScreen({super.key});

  @override
  State<ClientDispatchScreen> createState() => _ClientDispatchScreenState();
}

class _ClientDispatchScreenState extends State<ClientDispatchScreen> {
  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Despacho en Bodega'),
        ),
        // Mostrar mensaje de éxito cuando se complete el despacho
        onEndDrawerChanged: (isOpen) {
          if (!isOpen && context.mounted) {
            final provider = context.read<GuideProvider>();
            if (provider.lastOperationSuccessful) {
              _showSuccessMessage(context, 'Guía despachada exitosamente');
              provider.clearLastOperationStatus();
            }
          }
        },
        drawer: const AppDrawer(),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Builder(
            builder: (context) => RepaintBoundary(
              child: Consumer2<GuideProvider, AuthProvider>(
                child: const Divider(height: 1),
                builder: (context, guideProvider, authProvider, child) {
                  return Column(
                    children: [
                      _buildCourierSelector(guideProvider, authProvider),
                      _buildScanBox(guideProvider),
                      child!, // Usar el child pre-construido
                      _buildErrorMessage(guideProvider),
                      _buildGuideList(),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Selector de mensajero
  Widget _buildCourierSelector(
      GuideProvider guideProvider,
      AuthProvider authProvider,
      ) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Autocomplete<int>(
          key: ValueKey(guideProvider.selectedSubcourierId),
          fieldViewBuilder:
              (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: 'Seleccionar Subcourier',
                hintText: 'Escriba o seleccione un subcourier',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Buscar subcourier',
                  onPressed: () {
                    if (!focusNode.hasFocus) {
                      focusNode.requestFocus();
                    }
                  },
                ),
              ),
            );
          },
          initialValue: TextEditingValue(
            text: authProvider.subcouriers
                .firstWhere(
                  (sub) => sub.id == guideProvider.selectedSubcourierId,
              orElse: () => SubcourierInfo(id: 0, name: ''),
            )
                .name ??
                '',
          ),
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return authProvider.subcouriers.map((sub) => sub.id);
            }
            return authProvider.subcouriers
                .where(
                  (sub) => (sub.name ?? '')
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase()),
            )
                .map((sub) => sub.id);
          },
          displayStringForOption: (int subcourierId) {
            return authProvider.subcouriers
                .firstWhere((sub) => sub.id == subcourierId)
                .name ??
                'Sin nombre';
          },
          onSelected: (int value) {
            guideProvider.setSelectedSubcourier(value);
          },
        ),
      ),
    );
  }

  /// Box de escaneo en la parte superior
  Widget _buildScanBox(GuideProvider guideProvider) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        child: guideProvider.isLoading
            ? const LinearProgressIndicator()
            : const ClientDispatchScanBox(),
      ),
    );
  }

  /// Mensaje de error (si existe)
  Widget _buildErrorMessage(GuideProvider guideProvider) {
    return ValueListenableBuilder<String?>(
      valueListenable: guideProvider.errorNotifier,
      builder: (context, error, _) {
        if (error == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            error,
            style: const TextStyle(color: Colors.red),
          ),
        );
      },
    );
  }

  /// Lista de guías
  Widget _buildGuideList() {
    return const Expanded(
      child: ClientDispatchListScreen(),
    );
  }
}
