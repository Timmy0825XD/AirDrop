import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart' show Icons;

/// Íconos de contorno compartidos por las pantallas que ya se rediseñaron.
/// El logo y el dron de la marca mantienen sus dibujos propios.
abstract final class AppIcons {
  static const home = LucideIcons.house;
  static const orders = LucideIcons.package;
  // Única excepción de relleno: el usuario eligió el rayo sólido para la urgencia.
  static const urgency = Icons.bolt_rounded;
  static const plans = LucideIcons.calendarSync;
  static const createPlan = LucideIcons.calendarPlus;
  static const profile = LucideIcons.userRound;
  static const notifications = LucideIcons.bell;
  static const medication = LucideIcons.pill;
  static const next = LucideIcons.chevronRight;
  static const forward = LucideIcons.arrowRight;
  static const hub = LucideIcons.hospital;
  static const destination = LucideIcons.mapPin;
  static const search = LucideIcons.search;
  static const close = LucideIcons.x;
  static const add = LucideIcons.plus;
  static const check = LucideIcons.check;
  static const deliveryCode = LucideIcons.scanLine;
  static const settings = LucideIcons.settings;
  static const contact = LucideIcons.phone;
  static const allergies = LucideIcons.clipboardPlus;
  static const accessibility = LucideIcons.personStanding;
  static const privacy = LucideIcons.shieldCheck;
  static const signOut = LucideIcons.logOut;
  static const mail = LucideIcons.mail;
  static const back = LucideIcons.arrowLeft;
  static const calendar = LucideIcons.calendarDays;
  static const clock = LucideIcons.clock;
  static const repeat = LucideIcons.repeat2;
  static const people = LucideIcons.usersRound;
  static const edit = LucideIcons.pencil;
  static const document = LucideIcons.clipboardList;
  static const coldChain = LucideIcons.snowflake;
  static const more = LucideIcons.ellipsis;
  static const incoming = LucideIcons.packageCheck;
  static const transfer = LucideIcons.arrowLeftRight;
  static const flight = LucideIcons.navigation;
  static const lock = LucideIcons.lockKeyhole;
  static const unavailable = LucideIcons.cloudOff;
  static const warning = LucideIcons.triangleAlert;
  static const trash = LucideIcons.trash2;
  static const history = LucideIcons.history;
  static const info = LucideIcons.info;
  static const power = LucideIcons.power;
}
