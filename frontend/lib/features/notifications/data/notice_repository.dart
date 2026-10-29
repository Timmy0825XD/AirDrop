import 'notice_models.dart';

/// Contrato de la bandeja de avisos; cualquier rol autenticado.
abstract class NoticeRepository {
  /// `GET /notifications` (o `?unread=true`) — hasta 50, lo más nuevo
  /// primero.
  Future<List<AppNotice>> list({bool unreadOnly = false});

  /// `PATCH /notifications/:id/read` — 404 si el aviso no es suyo.
  Future<AppNotice> markRead(String id);

  /// `POST /notifications/read-all` — cuántos marcó.
  Future<int> markAllRead();
}
