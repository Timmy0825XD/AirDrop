import 'package:flutter/material.dart';

import '../../../../core/colombian_phone.dart';
import '../../data/hub_models.dart';

/// Los seis campos del alta de central en un solo objeto.
///
/// No pinta nada: solo conserva los controladores, los libera y arma el body
/// de `POST /hubs`. Existe para no arrastrar seis parámetros por cada widget
/// del formulario.
class HubFormValues {
  final name = TextEditingController();
  final address = TextEditingController();
  final latitude = TextEditingController();
  final longitude = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();

  void dispose() {
    for (final controller in [name, address, latitude, longitude, phone, email]) {
      controller.dispose();
    }
  }

  /// El celular se normaliza aquí, igual que en el registro: Nest solo quita
  /// lo que no es dígito y exige 10 dígitos. El correo vacío se omite porque
  /// `CreateHubDto` lo trata como opcional.
  CreateHubRequest request(HubType type) => CreateHubRequest(
    name: name.text.trim(),
    type: type,
    address: address.text.trim(),
    latitude: double.parse(latitude.text.trim()),
    longitude: double.parse(longitude.text.trim()),
    contactPhone: normalizeColombianPhone(phone.text),
    contactEmail: email.text.trim().isEmpty ? null : email.text.trim(),
  );
}
