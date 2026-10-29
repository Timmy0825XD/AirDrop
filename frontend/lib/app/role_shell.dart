import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/floating_nav_bar.dart';
import '../core/widgets/nav_scope.dart';
import '../features/auth/presentation/auth_controller.dart';
import 'role_tabs.dart';

/// El marco de las pantallas con sesión: la pantalla y, encima, la barra
/// flotante del rol. En los destinos de la barra se ve; en un detalle o un
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
    final tabs = RoleTabs.of(role, context, ref);
    final selected = tabs.indexOf(widget.location);
    final onTab = tabs.isTab(widget.location);
    final media = MediaQuery.of(context);
    final inset = onTab ? FloatingNavBar.height : 0.0;
    return NavScope(
      isTabRoot: onTab,
      child: Stack(
        children: [
          NotificationListener<UserScrollNotification>(
            onNotification: _onScroll,
            // La pantalla deja libre el alto de la barra al final.
            child: MediaQuery(
              // El scaffold ubica los botones flotantes con viewPadding.
              data: media.copyWith(
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
            left: 16,
            right: 16,
            bottom: media.padding.bottom + 12,
            child: FloatingNavBar(
              destinations: tabs.destinations,
              selected: selected,
              onSelect: (i) => context.go(tabs.paths[i]),
              center: tabs.center,
              collapsed: !onTab || _scrolledAway,
            ),
          ),
        ],
      ),
    );
  }
}
