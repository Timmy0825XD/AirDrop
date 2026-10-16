import '../data/order_models.dart';

/// `createdAt` es `timestamptz`: se muestra en hora de Bogotá. Sin paquete
/// de zonas horarias, se usa la hora local del dispositivo con el rótulo.
String formatBogota(DateTime? value) {
  if (value == null) return 'Sin fecha';
  final local = value.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '$d/$m/${local.year} $h:$min';
}

/// Hoy en `AAAA-MM-DD` para el mínimo del selector de fecha.
String todayIso() {
  final now = DateTime.now();
  return _isoOf(now);
}

String _isoOf(DateTime value) {
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  return '${value.year}-$m-$d';
}

String isoOf(DateTime value) => _isoOf(value);

/// Coordenada opcional: vacías las dos o las dos con máximo 6 decimales.
double? parseCoord(String raw, {required bool isLatitude}) {
  final value = raw.trim();
  if (value.isEmpty) return null;
  final parsed = double.tryParse(value);
  if (parsed == null) throw const FormatException('Coordenada no numérica.');
  if (isLatitude && (parsed < -90 || parsed > 90)) {
    throw const FormatException('La latitud no es válida.');
  }
  if (!isLatitude && (parsed < -180 || parsed > 180)) {
    throw const FormatException('La longitud no es válida.');
  }
  final parts = value.replaceFirst('-', '').split('.');
  if (parts.length == 2 && parts[1].length > 6) {
    throw const FormatException('Las coordenadas admiten hasta 6 decimales.');
  }
  return parsed;
}

/// Distancia del corredor con coma decimal: `4,2 km`.
String formatKm(double km) =>
    '${km.toStringAsFixed(1).replaceAll('.', ',')} km';

/// Un programado con fecha posterior a hoy en Bogotá (UTC−5, sin horario de
/// verano) todavía no se puede autorizar: Nest respondería 400.
bool isFutureSchedule(String? scheduledFor) {
  if (scheduledFor == null) return false;
  final bogota = DateTime.now().toUtc().subtract(const Duration(hours: 5));
  return scheduledFor.compareTo(_isoOf(bogota)) > 0;
}

/// Etiqueta de destino de la cola: persona o central.
String destinationLabel(Order order) {
  return order.destinationKind == DestinationKind.hub ? 'Central' : 'Persona';
}

/// "Dron D-01 · 4,2 km · 100 m": el dron y el corredor que reservó el
/// motor al autorizar. Sin asignación no debería llegar, pero no se cae.
String routeLine(OrderAssignment? a) {
  if (a == null) return 'Sin dron asignado';
  return 'Dron ${a.identifier} · ${formatKm(a.distanceKm)} · '
      '${a.altitudeM.round()} m';
}
