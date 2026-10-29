import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/balanced_grid.dart';

void main() {
  test('reparte en filas parejas, sin un cuadro suelto', () {
    // La telemetría: hasta 3 por fila.
    expect(BalancedGrid.rowSizes(5, 3), [3, 2]);
    expect(BalancedGrid.rowSizes(6, 3), [3, 3]);
    expect(BalancedGrid.rowSizes(4, 3), [2, 2]);
    expect(BalancedGrid.rowSizes(2, 3), [2]);
    // Los inicios: dos columnas; con impares la última va a todo el ancho.
    expect(BalancedGrid.rowSizes(3, 2), [2, 1]);
    expect(BalancedGrid.rowSizes(9, 2), [2, 2, 2, 2, 1]);
    expect(BalancedGrid.rowSizes(0, 2), isEmpty);
  });
}
