import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/field_limits.dart';
import '../../../core/widgets/error_banner.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../inventory/data/inventory_models.dart' show SaleType;
import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'order_format.dart';

/// Plan civil (`POST /orders/plans`). Sin descripción. Cantidad,
/// frecuencia y fecha de inicio obligatorias.
class PlanFormScreen extends ConsumerStatefulWidget {
  const PlanFormScreen({super.key});

  @override
  ConsumerState<PlanFormScreen> createState() => _PlanFormScreenState();
}

class _PlanFormScreenState extends ConsumerState<PlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  CatalogOffer? _offer;
  final _quantity = TextEditingController(text: '1');
  PlanFrequency _frequency = PlanFrequency.weekly;
  String _startDate = '';
  final _address = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  Uint8List? _bytes;
  String? _mime;
  String? _error;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _startDate = todayIso();
  }

  @override
  void dispose() {
    _quantity.dispose();
    _address.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  bool get _needsRx => _offer?.saleType == SaleType.prescription;

  Future<void> _pick() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
    );
    if (files.isEmpty) return;
    final file = files.first;
    final data = await file.readAsBytes();
    if (data.lengthInBytes > 2 * 1024 * 1024) {
      setState(() => _error = 'La imagen de la fórmula debe pesar hasta 2 MB.');
      return;
    }
    setState(() {
      _bytes = data;
      _mime = (file.extension ?? '').toLowerCase() == 'png'
          ? 'image/png'
          : 'image/jpeg';
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _startDate = isoOf(picked));
  }

  Future<void> _submit() async {
    if (_offer == null) {
      setState(() => _error = 'Elige un medicamento del catálogo.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final qty = int.tryParse(_quantity.text.trim());
    final stock = _offer!.availableQuantity;
    if (qty == null || qty < 1 || qty > 100000) {
      setState(() => _error = 'La cantidad debe ser un entero entre 1 y 100000.');
      return;
    }
    if (stock != null && qty > stock) {
      setState(() => _error = 'La cantidad supera el stock de esa fila.');
      return;
    }
    if (_startDate.compareTo(todayIso()) < 0) {
      setState(() => _error = 'La fecha de inicio no puede ser anterior a hoy.');
      return;
    }
    final latRaw = _latitude.text.trim();
    final lngRaw = _longitude.text.trim();
    if ((latRaw.isEmpty) != (lngRaw.isEmpty)) {
      setState(() => _error = 'La ubicación lleva latitud y longitud juntas.');
      return;
    }
    double? lat;
    double? lng;
    try {
      lat = latRaw.isEmpty ? null : parseCoord(latRaw, isLatitude: true);
      lng = lngRaw.isEmpty ? null : parseCoord(lngRaw, isLatitude: false);
    } on FormatException catch (e) {
      setState(() => _error = e.message);
      return;
    }
    final user = ref.read(authControllerProvider).asData?.value.user;
    if (_needsRx && (_bytes == null || _mime == null)) {
      setState(
        () => _error = 'La venta bajo fórmula exige la imagen de la fórmula.',
      );
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final request = CreatePlanRequest(
        medicationName: _offer!.name,
        saleType: _offer!.saleType,
        quantity: qty,
        frequency: _frequency,
        startDate: _startDate,
        address: _address.text.trim(),
        latitude: lat,
        longitude: lng,
        patientDocumentType: _needsRx ? user?.documentType : null,
        patientDocumentNumber: _needsRx ? user?.documentNumber : null,
        prescriptionMime: _needsRx ? _mime : null,
        prescriptionImageBase64: _needsRx ? base64Encode(_bytes!) : null,
      );
      final plan = await ref.read(createPlanProvider.notifier).create(request);
      if (mounted) context.go('/orders/plans/${plan.id}');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Entrega periódica')),
      body: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (offers) {
          final rows = offers
              .where((e) => e.saleType != SaleType.specialControl)
              .toList();
          if (rows.isEmpty) {
            return const Center(
              child: Text('No hay medicamentos disponibles.'),
            );
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null) ...[
                  ErrorBanner(message: _error!),
                  const SizedBox(height: 12),
                ],
                DropdownButtonFormField<CatalogOffer>(
                  initialValue: _offer,
                  decoration: const InputDecoration(labelText: 'MEDICAMENTO'),
                  items: [
                    for (final o in rows)
                      DropdownMenuItem(
                        value: o,
                        child: Text('${o.name} · ${o.saleType.label}'),
                      ),
                  ],
                  onChanged: (v) => setState(() => _offer = v),
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
                DropdownButtonFormField<PlanFrequency>(
                  initialValue: _frequency,
                  decoration: const InputDecoration(labelText: 'FRECUENCIA'),
                  items: [
                    for (final f in PlanFrequency.values)
                      DropdownMenuItem(value: f, child: Text(f.label)),
                  ],
                  onChanged: (v) =>
                      setState(() => _frequency = v ?? _frequency),
                ),
                Row(
                  children: [
                    Expanded(child: Text('Inicio: $_startDate')),
                    TextButton(
                      onPressed: _pickDate,
                      child: const Text('Elegir fecha'),
                    ),
                  ],
                ),
                TextFormField(
                  controller: _address,
                  maxLength: FieldLimits.address,
                  decoration: const InputDecoration(labelText: 'DIRECCIÓN'),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Obligatoria (1-160).' : null,
                ),
                Text(
                  'Se crean las entregas de las próximas 8 semanas. '
                  'La frecuencia única es una sola fecha.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_needsRx) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pick,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('Adjuntar fórmula'),
                  ),
                  if (_bytes != null) Image.memory(_bytes!, height: 120),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _sending ? null : _submit,
                  child: Text(_sending ? 'Enviando...' : 'Programar entrega'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
