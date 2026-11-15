import '../../../core/prefs/app_prefs.dart';
import '../../auth/data/auth_models.dart';

/// Si al ir a [location] toca mostrar antes la bienvenida (RF-53): solo al
/// solicitante, solo camino al inicio y solo si este teléfono no la ha
/// visto. Si las preferencias no se pudieron abrir no se muestra: saldría
/// en cada ingreso, porque no habría dónde anotar que ya se vio.
bool shouldShowWelcome({
  required UserRole? role,
  required String location,
  required PrefsStore prefs,
}) {
  if (location != '/home' || role != UserRole.requester) return false;
  if (!prefs.available) return false;
  return !(prefs.getBool(PrefKeys.onboardingSeen) ?? false);
}
