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

/// Urgencia civil (`POST /orders/emergencies`). Cantidad fija en el copy:
/// `1 unidad`, no es un campo.
class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen> {
  final _formKey = GlobalKey<FormState>();
  CatalogOffer? _offer;
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  Uint8List? _prescriptionBytes;
  String? _prescriptionMime;
  String? _error;
  bool _sending = false;

  @override
  void dispose() {
    _description.dispose();
    _address.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  bool get _needsPrescription => _offer?.saleType == SaleType.prescription;

  Future<void> _pickPrescription() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
    );
    if (files.isEmpty) return;
    final file = files.first;
    final bytes = await file.readAsBytes();
    if (bytes.lengthInBytes > 2 * 1024 * 1024) {
      setState(() => _error = 'La imagen de la fórmula debe pesar hasta 2 MB.');
      return;
    }
    final ext = (file.extension ?? '').toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    setState(() {
      _prescriptionBytes = bytes;
      _prescriptionMime = mime;
      _error = null;
    });
  }

  Future<void> _submit() async {
    final auth = ref.read(authControllerProvider).asData?.value;
    final user = auth?.user;
    if (_offer == null) {
      setState(() => _error = 'Elige un medicamento del catálogo.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final latRaw = _latitude.text.trim();
    final lngRaw = _longitude.text.trim();
    if ((latRaw.isEmpty) != (lngRaw.isEmpty)) {
      setState(
        () => _error = 'La ubicación lleva latitud y longitud juntas.',
      );
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
    if (_needsPrescription) {
      if (_prescriptionBytes == null || _prescriptionMime == null) {
        setState(
          () => _error = 'La venta bajo fórmula exige la imagen de la fórmula.',
        );
        return;
      }
      if (user?.documentType == null || user?.documentNumber == null) {
        setState(
          () => _error =
              'El documento de la cuenta debe ser el del paciente de la fórmula.',
        );
        return;
      }
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final request = CreateEmergencyRequest(
        medicationName: _offer!.name,
        saleType: _offer!.saleType,
        description: _description.text.trim(),
        address: _address.text.trim(),
        latitude: lat,
        longitude: lng,
        patientDocumentType: _needsPrescription ? user!.documentType : null,
        patientDocumentNumber: _needsPrescription
            ? user!.documentNumber
            : null,
        prescriptionMime: _needsPrescription ? _prescriptionMime : null,
        prescriptionImageBase64: _needsPrescription
            ? base64Encode(_prescriptionBytes!)
            : null,
      );
      final order = await ref
          .read(createEmergencyProvider.notifier)
          .create(request);
      if (mounted) context.go('/orders/${order.id}');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pedir urgencia')),
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
          final user = auth.asData?.value.user;
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
                  decoration: const InputDecoration(
                    labelText: 'MEDICAMENTO',
                  ),
                  items: [
                    for (final o in rows)
                      DropdownMenuItem(
                        value: o,
                        child: Text(
                          '${o.name} · ${o.saleType.label}'
                          '${o.requiresColdChain ? ' · Requiere frío' : ''}',
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _offer = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  maxLength: FieldLimits.orderDescription,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'DESCRIPCIÓN',
                  ),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty || t.length > FieldLimits.orderDescription) {
                      return 'La descripción es obligatoria (1-500).';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _address,
                  maxLength: FieldLimits.address,
                  decoration: const InputDecoration(labelText: 'DIRECCIÓN'),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty || t.length > FieldLimits.address) {
                      return 'La dirección es obligatoria (1-160).';
                    }
                    return null;
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitude,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'LATITUD',
                          hintText: 'Opcional',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _longitude,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'LONGITUD',
                          hintText: 'Opcional',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Si no tienes la ubicación, deja estos campos vacíos.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Cantidad: 1 unidad.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (_needsPrescription) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Documento: ${user?.documentType?.apiValue ?? ''} '
                    '${user?.documentNumber ?? ''}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickPrescription,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('Adjuntar fórmula'),
                  ),
                  if (_prescriptionBytes != null) ...[
                    const SizedBox(height: 8),
                    Image.memory(_prescriptionBytes!, height: 120),
                    Text(
                      '${(_prescriptionBytes!.lengthInBytes / 1024).toStringAsFixed(1)} KB',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
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
