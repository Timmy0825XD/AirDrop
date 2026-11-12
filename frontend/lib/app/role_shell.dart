import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/app_max_width.dart';
import '../core/widgets/app_tab_bar.dart';
import '../core/widgets/nav_scope.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/tracking/data/tracking_providers.dart';
import 'role_tabs.dart';

/// El marco de las pantallas con sesión: la pantalla y, abajo, la barra de
/// pestañas del rol. En los destinos de la barra se ve; en un detalle o un
/// formulario se esconde deslizándose, igual que al bajar en una lista.
class RoleShell extends ConsumerStatefulWidget {
  const RoleShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  ConsumerState<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends ConsumerState<RoleShell> {
  bool _scrolledAway = false;

  bool _onScroll(UserScrollNotification note) {
    // Solo la lista principal (profundidad 0), no un carrusel adentro.
    if (note.depth != 0 || note.metrics.axis != Axis.vertical) return false;
    final away = switch (note.direction) {
      ScrollDirection.reverse => true,
      ScrollDirection.forward => false,
      ScrollDirection.idle => _scrolledAway,
    };
    if (away != _scrolledAway) setState(() => _scrolledAway = away);
    return false;
  }

  @override
  void didUpdateWidget(RoleShell old) {
    super.didUpdateWidget(old);
    // Cada pantalla nueva arranca con la barra a la vista.
    if (old.location != widget.location) _scrolledAway = false;
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authControllerProvider).value?.user?.role;
    if (role == null) return widget.child;
    // La hora simulada de la consola, toda la sesión (RF-31).
    ref.watch(clockSyncProvider);
    final tabs = RoleTabs.of(role, context, ref);
    final selected = tabs.indexOf(widget.location);
    final onTab = tabs.isTab(widget.location);
    final media = MediaQuery.of(context);
    final inset = onTab ? AppTabBar.height : 0.0;
    return NavScope(
      isTabRoot: onTab,
      child: AppMaxWidth(
        child: Stack(
          children: [
            NotificationListener<UserScrollNotification>(
              onNotification: _onScroll,
              // La pantalla deja libre el alto de la barra al final.
              child: MediaQuery(
                // El scaffold ubica los botones flotantes con viewPadding. El
                // ancho es el de la columna (`AppMaxWidth`), no el de la
                // ventana.
                data: media.copyWith(
                  size: Size(
                    media.size.width.clamp(0, AppMaxWidth.defaultMaxWidth),
                    media.size.height,
                  ),
                  padding: media.padding.copyWith(
                    bottom: media.padding.bottom + inset,
                  ),
                  viewPadding: media.viewPadding.copyWith(
                    bottom: media.viewPadding.bottom + inset,
                  ),
                ),
                child: widget.child,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AppTabBar(
                destinations: tabs.destinations,
                selected: selected,
                onSelect: (i) => context.go(tabs.paths[i]),
                center: tabs.center,
                centerActive: tabs.isCenter(widget.location),
                collapsed: !onTab || _scrolledAway,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
