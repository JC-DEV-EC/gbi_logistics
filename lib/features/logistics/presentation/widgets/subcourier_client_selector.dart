import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/guide_validation_provider.dart';
import '../../models/auth_models.dart';
import '../../models/validate_guide_models.dart';

/// Widget para selección de subcourier y cliente
class SubcourierClientSelector extends StatefulWidget {
  final void Function(int?) onSubcourierSelected;
  final void Function(String?) onClientSelected;
  final bool isLocked;
  final void Function(bool requiresClient)? onRequiresClientChanged;

  const SubcourierClientSelector({
    super.key,
    required this.onSubcourierSelected,
    required this.onClientSelected,
    this.isLocked = false,
    this.onRequiresClientChanged,
  });

  @override
  State<SubcourierClientSelector> createState() => _SubcourierClientSelectorState();
}

class _SubcourierClientSelectorState extends State<SubcourierClientSelector> {
  SubcourierInfo? _selectedSubcourier;
  ClientBySubcourierItem? _selectedClient;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final validationProvider = context.watch<GuideValidationProvider>();

    return Column(
      children: [
        // Selector de Subcourier
        Autocomplete<SubcourierInfo>(
          initialValue: TextEditingValue(
            text: _selectedSubcourier?.name ?? '',
          ),
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return authProvider.subcouriers;
            }
            return authProvider.subcouriers.where(
              (sub) => (sub.name ?? '').toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  ),
            );
          },
          displayStringForOption: (option) => option.name ?? 'Sin nombre',
          onSelected: (SubcourierInfo subcourier) {
            setState(() {
              _selectedSubcourier = subcourier;
              _selectedClient = null; // Reset client selection
            });
            widget.onSubcourierSelected(subcourier.id);
            widget.onClientSelected(null);
            
            // Si el subcourier tiene showClients, cargar los clientes
            final requiresClient = subcourier.showClients == true;
            if (requiresClient) {
              debugPrint('[SubcourierClientSelector] Loading clients for subcourier ${subcourier.id} (showClients: ${subcourier.showClients})');
              validationProvider.loadClients(subcourier.id);
            } else {
              validationProvider.clearClients();
            }
            // Notificar al contenedor si requiere cliente
            widget.onRequiresClientChanged?.call(requiresClient);
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              enabled: !widget.isLocked,
              decoration: InputDecoration(
                labelText: 'Subcourier',
                hintText: 'Seleccione un subcourier',
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
        ),

        // Selector de Cliente (condicional)
        if (_selectedSubcourier?.showClients == true) ...[
          const SizedBox(height: 16),
          if (validationProvider.isLoading)
            const LinearProgressIndicator()
          else
            Autocomplete<ClientBySubcourierItem>(
              initialValue: TextEditingValue(
                text: _selectedClient?.name ?? '',
              ),
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return validationProvider.clients;
                }
                return validationProvider.clients.where(
                  (client) => (client.name ?? '').toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      ),
                );
              },
              displayStringForOption: (option) => option.name ?? 'Sin nombre',
              onSelected: (ClientBySubcourierItem client) {
                setState(() {
                  _selectedClient = client;
                });
                widget.onClientSelected(client.id);
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: !widget.isLocked,
                  decoration: InputDecoration(
                    labelText: 'Cliente',
                    hintText: 'Seleccione un cliente',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      tooltip: 'Buscar cliente',
                      onPressed: () {
                        if (!focusNode.hasFocus) {
                          focusNode.requestFocus();
                        }
                      },
                    ),
                  ),
                );
              },
            ),
        ],
      ],
    );
  }
}