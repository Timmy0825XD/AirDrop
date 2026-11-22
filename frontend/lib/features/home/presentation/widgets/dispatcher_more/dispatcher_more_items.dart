import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/widgets/menu_list.dart';
import '../../../../../theme/app_icons.dart';
import '../dispatcher/dispatcher_counts.dart';

typedef MoreOpen = VoidCallback? Function(String path, {bool always});

List<MenuItem> dispatcherOrderItems(MoreOpen open, DispatcherCounts? counts) =>
    [
      MenuItem(
        title: 'Traslados entrantes',
        subtitle: 'Lo que otras centrales te envían',
        icon: AppIcons.incoming,
        count: counts?.incoming,
        onTap: open('/orders/incoming'),
      ),
      MenuItem(
        title: 'Pendiente de carga',
        subtitle: 'Drones esperando el insumo',
        icon: AppIcons.orders,
        count: counts?.pendingLoad,
        urgent: true,
        onTap: open('/orders/pending-load'),
      ),
      MenuItem(
        title: 'Vuelos en curso',
        subtitle: 'Ida, entrega o regreso',
        icon: AppIcons.drone,
        count: counts?.inFlight,
        onTap: open('/orders/in-flight'),
      ),
      MenuItem(
        title: 'Programados',
        subtitle: 'Entregas por preparar',
        icon: AppIcons.calendar,
        onTap: open('/orders/scheduled'),
      ),
      MenuItem(
        title: 'Historial',
        subtitle: 'Pedidos cerrados',
        icon: AppIcons.history,
        onTap: open('/orders/history'),
      ),
    ];

List<MenuItem> dispatcherRequestItems(BuildContext context, MoreOpen open) => [
  MenuItem(
    title: 'Urgencia a otra central',
    subtitle: 'Pide un insumo para tu central',
    icon: AppIcons.transfer,
    onTap: open('/orders/hub-emergency'),
  ),
  MenuItem(
    title: 'Nuevo abastecimiento',
    subtitle: 'Programa entregas periódicas',
    icon: AppIcons.createPlan,
    onTap: open('/orders/hub-plans/new'),
  ),
  MenuItem(
    title: 'Mis abastecimientos',
    subtitle: 'Consulta tus planes',
    icon: AppIcons.plans,
    onTap: () => context.push('/orders/plans'),
  ),
];

List<MenuItem> dispatcherHubItems(MoreOpen open) => [
  MenuItem(
    title: 'Información de la central',
    subtitle: 'Ubicación, estado y contacto',
    icon: AppIcons.hub,
    onTap: open('/hubs/me', always: true),
  ),
  MenuItem(
    title: 'Cuarentena',
    subtitle: 'Insumos que no regresan al stock',
    icon: AppIcons.privacy,
    onTap: open('/inventory/quarantine'),
  ),
];

List<MenuItem> dispatcherAccountItems(BuildContext context) => [
  MenuItem(
    title: 'Mi perfil',
    subtitle: 'Tus datos y tu central',
    icon: AppIcons.profile,
    onTap: () => context.push('/profile'),
  ),
  MenuItem(
    title: 'Ajustes de la app',
    subtitle: 'Tema, texto y accesibilidad',
    icon: AppIcons.settings,
    onTap: () => context.push('/settings'),
  ),
];
