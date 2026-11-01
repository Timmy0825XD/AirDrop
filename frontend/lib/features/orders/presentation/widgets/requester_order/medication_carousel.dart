import 'package:flutter/material.dart';

import '../../../../../core/widgets/press_scale.dart';
import '../../../../auth/presentation/widgets/auth_field.dart';
import '../../../../auth/presentation/widgets/search_picker_sheet.dart';
import '../../../../inventory/data/inventory_models.dart' show SaleType;
import '../../../data/order_models.dart';
import '../offer_option.dart';
import 'requester_order_fields.dart';
import 'requester_order_values.dart';

/// El medicamento en tarjetas que se deslizan de lado: cada una con su
/// ícono (frío o pastilla), el nombre y lo que hay en stock. La primera
/// abre el buscador, para cuando la lista es larga. La elegida se enciende
/// con el acento.
class MedicationCarousel extends StatelessWidget {
  const MedicationCarousel({
    super.key,
    required this.offers,
    required this.form,
  });

  final List<CatalogOffer> offers;
  final RequesterOrderForm form;

  List<CatalogOffer> get _choices => [
    for (final offer in offers)
      if (offer.saleType != SaleType.specialControl) offer,
  ];

  bool _isSelected(CatalogOffer offer) =>
      offer.name == form.values.offer?.name &&
      offer.saleType == form.values.offer?.saleType;

  void _choose(CatalogOffer offer) {
    form.values.offer = offer;
    form.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final choices = _choices;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Header(),
        const SizedBox(height: 8),
        SizedBox(
          height: 124,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: choices.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) => i == 0
                ? _SearchCard(
                    options: [for (final o in choices) offerOption(o)],
                    isSelected: _isSelected,
                    onPicked: _choose,
                  )
                : _OfferCard(
                    offer: choices[i - 1],
                    selected: _isSelected(choices[i - 1]),
                    onTap: () => _choose(choices[i - 1]),
                  ),
          ),
        ),
        AuthFieldError(message: form.errors[RequesterInput.offer]),
      ],
    );
  }
}

/// Una tarjeta del carrusel.
class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.selected,
    required this.onTap,
  });

  final CatalogOffer offer;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final stock = [
      if (offer.requiresColdChain) 'FRÍO',
      if (offer.availableQuantity case final qty?) '$qty U',
    ].join(' · ');
    return _CardShell(
      selected: selected,
      onTap: onTap,
      semantics: offer.name,
      children: [
        Icon(
          offer.requiresColdChain
              ? Icons.ac_unit_rounded
              : Icons.medication_outlined,
          color: offer.requiresColdChain || selected ? accent : null,
        ),
        const Spacer(),
        Text(
          offer.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(height: 1.2),
        ),
        const SizedBox(height: 4),
        Text(stock, style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
      ],
    );
  }
}

/// La primera tarjeta: abre el buscador.
class _SearchCard extends StatelessWidget {
  const _SearchCard({
    required this.options,
    required this.isSelected,
    required this.onPicked,
  });

  final List<PickerOption<CatalogOffer>> options;
  final bool Function(CatalogOffer) isSelected;
  final ValueChanged<CatalogOffer> onPicked;

  Future<void> _search(BuildContext context) async {
    final picked = await showSearchPicker<CatalogOffer>(
      context,
      title: '¿Qué medicamento necesitas?',
      searchHint: 'Busca por nombre',
      options: options,
      isSelected: isSelected,
    );
    if (picked != null) onPicked(picked.value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _CardShell(
      selected: false,
      onTap: () => _search(context),
      semantics: 'Buscar medicamento',
      width: 96,
      children: [
        Icon(Icons.search_rounded, color: theme.colorScheme.primary),
        const Spacer(),
        Text('Buscar', style: theme.textTheme.titleSmall),
        Text(
          'Todos',
          style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
        ),
      ],
    );
  }
}

/// El vidrio de la tarjeta; elegida, con el borde y el tinte del acento.
class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.selected,
    required this.onTap,
    required this.semantics,
    required this.children,
    this.width = 128,
  });

  final bool selected;
  final VoidCallback onTap;
  final String semantics;
  final List<Widget> children;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = colors.primary;
    return Semantics(
      button: true,
      selected: selected,
      label: semantics,
      child: PressScale(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: width,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected
                  ? accent.withValues(alpha: 0.12)
                  : colors.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? accent.withValues(alpha: 0.7)
                    : colors.onSurface.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

/// "MEDICAMENTO" a la izquierda y "EN STOCK" a la derecha.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final label = Theme.of(context).textTheme.labelSmall;
    return Row(
      children: [
        Text('MEDICAMENTO', style: label),
        const Spacer(),
        Text('EN STOCK', style: label),
      ],
    );
  }
}
