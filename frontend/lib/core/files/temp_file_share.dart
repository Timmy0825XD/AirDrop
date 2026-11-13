import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// "Abrir con…" para un archivo sensible (la fórmula, RF-27): lo escribe en
/// una carpeta temporal propia, abre el menú del teléfono para pasarlo a
/// otra app y lo borra con [clear]. No lo guarda en la galería ni en las
/// descargas. Es una clase para poder cambiarla en las pruebas.
class TempFileShare {
  const TempFileShare();

  static const _folder = 'airdrop-abrir-con';

  Future<Directory> _dir() async {
    final base = await getTemporaryDirectory();
    return Directory('${base.path}${Platform.pathSeparator}$_folder');
  }

  Future<void> open({
    required Uint8List bytes,
    required String name,
    required String mime,
  }) async {
    final dir = await _dir();
    await dir.create(recursive: true);
    final file = File('${dir.path}${Platform.pathSeparator}$name');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mime, name: name)],
      ),
    );
  }

  /// Borra las copias. Se llama al cerrar el visor; si la app se cerró
  /// antes, el sistema limpia la carpeta temporal.
  Future<void> clear() async {
    final dir = await _dir();
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}

final tempFileShareProvider = Provider<TempFileShare>(
  (ref) => const TempFileShare(),
);
