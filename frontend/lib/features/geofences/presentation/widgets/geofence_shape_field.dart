import 'package:flutter/material.dart';

import '../../../../core/widgets/auth_field.dart';
import '../geofence_draw_screen.dart';
import 'geofence_polygon_preview.dart';
import 'geometry_draft.dart';

/// La forma con su error: el selector, la vista previa y el modo dibujar.
/// Cambia [draft] y avisa con [onChanged] para que la pantalla repinte.
class GeofenceShapeField extends StatelessWidget {
  const GeofenceShapeField({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.shakeCount,
    this.errorText,
  });

  final GeometryDraft draft;
  final VoidCallback onChanged;
  final int shakeCount;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShakeOnError(
          trigger: errorText == null ? 0 : shakeCount,
          child: GeofencePolygonPreview(
            draft: draft,
            onShape: (shape) {
              draft.shape = shape;
              onChanged();
            },
            onDraw: () async {
              final done = await GeofenceDrawScreen.open(context, draft);
              if (done && context.mounted) onChanged();
            },
          ),
        ),
        AuthFieldError(message: errorText),
      ],
    );
  }
}
