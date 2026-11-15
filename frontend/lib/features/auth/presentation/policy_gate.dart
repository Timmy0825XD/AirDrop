/// A dónde manda el router por la política de datos (RF-50), o `null` si
/// [location] puede seguir. Quien debe aceptar la política vigente solo
/// ve `/privacy/accept` (sin aceptar, Nest responde 403 al pedir); quien
/// ya la aceptó no se queda en esa pantalla.
String? policyRedirect({required bool mustAccept, required String location}) {
  const accept = '/privacy/accept';
  if (mustAccept == (location == accept)) return null;
  return mustAccept ? accept : '/home';
}
