import '../../data/hub_models.dart';

/// Copy de las centrales en español de Colombia.
///
/// El enum vive en `data/` y el texto acá, igual que `DocumentType` con
/// `DocumentTypeLabels`. Lo usan el listado, el formulario y el detalle
/// para que un mismo tipo no se diga de dos formas.
class HubLabels {
  HubLabels._();

  static String type(HubType type) => switch (type) {
    HubType.hospital => 'Hospital',
    HubType.clinic => 'Clínica',
    HubType.pharmacy => 'Farmacia',
    HubType.bloodBank => 'Banco de sangre',
    HubType.vaccination => 'Punto de vacunación',
  };

  static String status(HubStatus status) => switch (status) {
    HubStatus.active => 'Activa',
    HubStatus.suspended => 'Suspendida',
  };
}
