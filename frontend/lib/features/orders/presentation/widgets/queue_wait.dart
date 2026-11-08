import '../../../../core/widgets/status_pill.dart';

/// Minutos que lleva en la cola una urgencia, con la hora simulada (RF-31):
/// a x8 la espera sube al ritmo de la TV.
int queueWaitMinutes(DateTime? createdAt, DateTime now) {
  if (createdAt == null) return 0;
  final minutes = now.difference(createdAt).inMinutes;
  return minutes < 0 ? 0 : minutes;
}

/// "Espera 6 min", lo único que ordena la cola de un vistazo.
String queueWaitLabel(int minutes) =>
    minutes < 1 ? 'Recién llegada' : 'Espera $minutes min';

/// Ámbar a los 3 minutos y rojo a los 5, o antes si Nest ya la marcó sin
/// atender.
PillTone queueWaitTone(int minutes, {required bool unattended}) {
  if (unattended || minutes >= 5) return PillTone.negative;
  if (minutes >= 3) return PillTone.attention;
  return PillTone.neutral;
}
