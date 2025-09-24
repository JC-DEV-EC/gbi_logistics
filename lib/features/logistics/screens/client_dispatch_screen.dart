import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/auth_models.dart';
import '../providers/guide_provider.dart';
import '../presentation/widgets/client_dispatch_list_screen.dart';
import '../presentation/widgets/client_dispatch_scan_box.dart';
import '../presentation/widgets/app_drawer.dart';

/// Pantalla para despacho a cliente
class ClientDispatchScreen extends StatefulWidget {
  const ClientDispatchScreen({super.key});

  @override
  State<ClientDispatchScreen> createState() => _ClientDispatchScreenState();
}

class _ClientDispatchScreenState extends State<ClientDispatchScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Despacho a Cliente'),
      ),
      drawer: const AppDrawer(),
      body: Consumer2<GuideProvider, AuthProvider>(
        builder: (context, guideProvider, authProvider, _) {
          return Column(
            children: [
              _buildCourierSelector(guideProvider, authProvider),
              _buildScanBox(guideProvider),
              const Divider(height: 1),
              _buildErrorMessage(guideProvider),
              _buildGuideList(),
            ],
          );
        },
      ),
    );
  }

  /// Selector de mensajero
  Widget _buildCourierSelector(
      GuideProvider guideProvider,
      AuthProvider authProvider,
      ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Autocomplete<int>(
        key: ValueKey(guideProvider.selectedSubcourierId),
        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
          void _showAllOptions() {
            if (!focusNode.hasFocus) {
              focusNode.requestFocus();
            }
            // Forzar un cambio para que Autocomplete abra el overlay
            final original = textEditingController.text;
            textEditingController.value = textEditingController.value.copyWith(
              text: original + ' ',
              selection: TextSelection.collapsed(offset: (original + ' ').length),
            );
            Future.microtask(() {
              textEditingController.value = textEditingController.value.copyWith(
                text: original,
                selection: TextSelection.collapsed(offset: original.length),
              );
            });
          }

          return TextFormField(
            controller: textEditingController,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: 'Seleccionar Subcourier',
              hintText: 'Escriba o seleccione un subcourier',
              border: const OutlineInputBorder(),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    tooltip: 'Buscar subcourier',
                    onPressed: () {
                      if (!focusNode.hasFocus) {
                        focusNode.requestFocus();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_drop_down),
                    tooltip: 'Ver todos',
                    onPressed: _showAllOptions,
                  ),
                ],
              ),
            ),
          );
        },
        initialValue: TextEditingValue(
          text: authProvider.subcouriers
            .firstWhere(
              (sub) => sub.id == guideProvider.selectedSubcourierId,
              orElse: () => SubcourierInfo(id: 0, name: '')
            ).name ?? ''
        ),
        optionsBuilder: (textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return authProvider.subcouriers.map((sub) => sub.id);
          }
          return authProvider.subcouriers
            .where((sub) => 
              (sub.name ?? '').toLowerCase()
                .contains(textEditingValue.text.toLowerCase()))
            .map((sub) => sub.id);
        },
        displayStringForOption: (int subcourierId) {
          return authProvider.subcouriers
            .firstWhere((sub) => sub.id == subcourierId)
            .name ?? 'Sin nombre';
        },
        onSelected: (int value) {
          guideProvider.setSelectedSubcourier(value);
        },
      ),
    );
  }

  /// Box de escaneo en la parte superior
  Widget _buildScanBox(GuideProvider guideProvider) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: guideProvider.isLoading
          ? const LinearProgressIndicator()
          : const ClientDispatchScanBox(),
    );
  }

  /// Mensaje de error (si existe)
  Widget _buildErrorMessage(GuideProvider guideProvider) {
    if (guideProvider.error == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        guideProvider.error!,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  /// Lista de guías
  Widget _buildGuideList() {
    return const Expanded(
      child: ClientDispatchListScreen(),
    );
  }
}
