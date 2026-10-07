import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/error_banner.dart';
import '../../inventory/data/inventory_models.dart' show SaleType;
import '../data/order_models.dart';
import '../data/order_providers.dart';

/// Urgencia a otra central (`POST /orders/hub-emergencies`).
class HubEmergencyScreen extends ConsumerStatefulWidget {
  const HubEmergencyScreen({super.key});

  @override
  ConsumerState<HubEmergencyScreen> createState() => _HubEmergencyScreenState();
}

class _HubEmergencyScreenState extends ConsumerState<HubEmergencyScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _originHubId;
  CatalogOffer? _offer;
  final _quantity = TextEditingController(text: '1');
  String? _error;
  bool _sending = false;

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_originHubId == null || _offer == null) {
      setState(() => _error = 'Elige la central de origen y el medicamento.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final qty = int.tryParse(_quantity.text.trim());
    final stock = _offer!.availableQuantity ?? 100000;
    if (qty == null || qty < 1 || qty > 100000 || qty > stock) {
      setState(() => _error = 'Cantidad entera entre 1 y el stock de la fila.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final order = await ref
          .read(createHubEmergencyProvider.notifier)
          .create(
            CreateHubEmergencyRequest(
              originHubId: _originHubId!,
              medicationName: _offer!.name,
              saleType: _offer!.saleType,
              quantity: qty,
            ),
          );
      if (mounted) context.go('/orders/${order.id}');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final origins = ref.watch(originHubsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pedir a otra central')),
      body: origins.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (hubs) {
          if (hubs.isEmpty) {
            return const Center(child: Text('No hay otra central activa.'));
          }
          final catalog = _originHubId == null
              ? null
              : ref.watch(hubCatalogProvider(_originHubId!));
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null) ...[
                  ErrorBanner(message: _error!),
                  const SizedBox(height: 12),
                ],
                DropdownButtonFormField<String>(
                  initialValue: _originHubId,
                  decoration: const InputDecoration(labelText: 'ORIGEN'),
                  items: [
                    for (final h in hubs)
                      DropdownMenuItem(value: h.id, child: Text(h.name)),
                  ],
                  onChanged: (v) => setState(() {
                    _originHubId = v;
                    _offer = null;
                  }),
                ),
                if (catalog != null)
                  catalog.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: LinearProgressIndicator(),
                    ),
                    error: (e, _) => Text('$e'),
                    data: (offers) {
                      final rows = offers
                          .where((e) => e.saleType != SaleType.specialControl)
                          .toList();
                      return DropdownButtonFormField<CatalogOffer>(
                        initialValue: _offer,
                        decoration: const InputDecoration(
                          labelText: 'MEDICAMENTO',
                        ),
                        items: [
                          for (final o in rows)
                            DropdownMenuItem(
                              value: o,
                              child: Text(
                                '${o.name} · ${o.saleType.label} · Disp. ${o.availableQuantity ?? 0}',
                              ),
                            ),
                        ],
                        onChanged: (v) => setState(() => _offer = v),
                      );
                    },
                  ),
                TextFormField(
                  controller: _quantity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'CANTIDAD'),
                  validator: (v) {
                    final q = int.tryParse((v ?? '').trim());
                    if (q == null || q < 1) return 'Entero mayor o igual a 1.';
                    return null;
                  },
                ),
                Text(
                  'La fórmula de un paciente no va en un traslado.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _sending ? null : _submit,
                  child: Text(_sending ? 'Enviando...' : 'Pedir urgencia'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
