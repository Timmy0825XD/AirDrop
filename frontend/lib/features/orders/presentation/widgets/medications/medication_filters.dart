import 'package:flutter/material.dart';

import 'medication_rules.dart';

/// Buscar por nombre y filtrar por frío y por fórmula (RF-54). Va debajo
/// del título de la lista.
class MedicationFilters extends StatelessWidget {
  const MedicationFilters({
    super.key,
    required this.filter,
    required this.onChanged,
    required this.controller,
  });

  final MedicationFilter filter;
  final ValueChanged<MedicationFilter> onChanged;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          onChanged: (text) => onChanged(filter.copyWith(query: text)),
          decoration: InputDecoration(
            hintText: 'Busca por nombre',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: filter.query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Borrar la búsqueda',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      controller.clear();
                      onChanged(filter.copyWith(query: ''));
                    },
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            FilterChip(
              label: const Text('Viaja en frío'),
              avatar: const Icon(Icons.ac_unit_rounded, size: 18),
              selected: filter.coldOnly,
              onSelected: (on) => onChanged(filter.copyWith(coldOnly: on)),
            ),
            FilterChip(
              label: const Text('Bajo fórmula'),
              avatar: const Icon(Icons.description_rounded, size: 18),
              selected: filter.prescriptionOnly,
              onSelected: (on) =>
                  onChanged(filter.copyWith(prescriptionOnly: on)),
            ),
          ],
        ),
      ],
    );
  }
}
