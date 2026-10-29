import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/colombian_phone.dart';
import '../../../../core/validators.dart';
import '../../data/hub_models.dart';

/// Los campos del alta de central.
enum HubInput { name, address, location, phone, email }

/// Los campos del alta de central en un solo objeto.
///
/// No pinta nada: conserva los controladores, el tipo y el punto que se
/// tocó en el mapa; valida con `Validators` (los mismos mensajes de Nest)
/// y arma el body de `POST /hubs`.
class HubFormValues {
  final name = TextEditingController();
  final address = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  HubType type = HubType.hospital;

  /// Dónde queda la central; `null` hasta que se toca el mapa.
  LatLng? location;

  void dispose() {
    for (final controller in [name, address, phone, email]) {
      controller.dispose();
    }
  }

  /// Precarga una central para editarla.
  void load(Hub hub) {
    name.text = hub.name;
    address.text = hub.address;
    phone.text = hub.contactPhone;
    email.text = hub.contactEmail ?? '';
    type = hub.type;
    location = LatLng(hub.latitude, hub.longitude);
  }

  /// El body de `PATCH /hubs/:id`: solo lo que cambió frente a [original].
  /// Latitud y longitud van juntas, y solo si el punto se movió: así no se
  /// choca sin querer con el candado de "vuelos en curso".
  Map<String, dynamic> changes(Hub original) {
    final next = request();
    final moved =
        next.latitude != double.parse(original.latitude.toStringAsFixed(6)) ||
        next.longitude != double.parse(original.longitude.toStringAsFixed(6));
    return {
      if (next.name != original.name) 'name': next.name,
      if (next.type != original.type) 'type': next.type.apiValue,
      if (next.address != original.address) 'address': next.address,
      if (moved) ...{'latitude': next.latitude, 'longitude': next.longitude},
      if (next.contactPhone != original.contactPhone)
        'contactPhone': next.contactPhone,
      if (next.contactEmail != null &&
          next.contactEmail != original.contactEmail)
        'contactEmail': next.contactEmail,
    };
  }

  /// Un mensaje por campo con error; vacío si todo está bien. El correo
  /// es opcional en `CreateHubDto`: vacío pasa, pero si viene tiene que
  /// ser válido.
  Map<HubInput, String> validate() {
    final mail = email.text.trim();
    final errors = <HubInput, String?>{
      HubInput.name: Validators.hubName(name.text),
      HubInput.address: Validators.address(address.text),
      HubInput.location: location == null
          ? 'Toca el mapa para ubicar la central.'
          : null,
      HubInput.phone: Validators.phone(phone.text),
      HubInput.email: mail.isEmpty ? null : Validators.email(mail),
    };
    return {
      for (final entry in errors.entries)
        if (entry.value != null) entry.key: entry.value!,
    };
  }

  /// El celular se normaliza aquí, igual que en el registro: Nest solo
  /// quita lo que no es dígito y exige 10 dígitos. Las coordenadas se
  /// redondean a 6 decimales (unos 10 cm), como las de las geovallas.
  CreateHubRequest request() {
    final point = location!;
    final mail = email.text.trim();
    return CreateHubRequest(
      name: name.text.trim(),
      type: type,
      address: address.text.trim(),
      latitude: double.parse(point.latitude.toStringAsFixed(6)),
      longitude: double.parse(point.longitude.toStringAsFixed(6)),
      contactPhone: normalizeColombianPhone(phone.text),
      contactEmail: mail.isEmpty ? null : mail,
    );
  }
}
