import '../../../core/api_exception.dart';
import 'notice_models.dart';
import 'notice_repository.dart';

/// Bandeja para `DataSource.local`: un aviso por confirmar (sin leer) y
/// uno de despegue ya leído.
class LocalNoticeRepository implements NoticeRepository {
  final List<AppNotice> _rows = [
    AppNotice(
      id: 'n1',
      kind: NoticeKind.confirmDelivery,
      title: 'Confirma tu entrega programada',
      body:
          'Tu entrega de mañana espera tu confirmación. Si no confirmas 2 '
          'horas antes, se omite.',
      orderId: 'a5555555-5555-4555-8555-555555555555',
      createdAt: DateTime.now().toUtc().subtract(const Duration(minutes: 20)),
    ),
    AppNotice(
      id: 'n2',
      kind: NoticeKind.departed,
      title: 'Tu entrega programada salió',
      body: 'Ya va en camino. Llega alrededor de las 10:20.',
      readAt: DateTime.now().toUtc().subtract(const Duration(days: 1)),
      createdAt: DateTime.now().toUtc().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  Future<List<AppNotice>> list({bool unreadOnly = false}) async => [
    for (final row in _rows)
      if (!unreadOnly || row.unread) row,
  ];

  @override
  Future<AppNotice> markRead(String id) async {
    final index = _rows.indexWhere((row) => row.id == id);
    if (index < 0) {
      throw const ApiException('El aviso no existe.', statusCode: 404);
    }
    return _rows[index] = _rows[index].read(DateTime.now().toUtc());
  }

  @override
  Future<int> markAllRead() async {
    final now = DateTime.now().toUtc();
    final count = _rows.where((row) => row.unread).length;
    for (var i = 0; i < _rows.length; i++) {
      _rows[i] = _rows[i].read(now);
    }
    return count;
  }
}
