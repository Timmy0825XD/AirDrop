import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/data/data_source.dart';
import '../../../core/data/data_source_config.dart';
import '../../auth/presentation/auth_controller.dart';
import 'local_notice_repository.dart';
import 'notice_models.dart';
import 'notice_repository.dart';
import 'remote_notice_repository.dart';

final noticeRepositoryProvider = Provider<NoticeRepository>((ref) {
  // Otra cuenta, otro repositorio: los avisos de la anterior se descartan.
  ref.watch(sessionUserIdProvider);
  return switch (appDataSource) {
    DataSource.local => LocalNoticeRepository(),
    DataSource.remote => RemoteNoticeRepository(
      apiClient: ref.watch(apiClientProvider),
    ),
  };
});

/// La bandeja completa, lo más nuevo primero.
final noticesProvider = FutureProvider<List<AppNotice>>((ref) {
  return ref.watch(noticeRepositoryProvider).list();
});

/// Cuántos avisos sin leer hay: la insignia de la campana.
final unreadCountProvider = FutureProvider<int>((ref) async {
  final rows = await ref.watch(noticeRepositoryProvider).list(unreadOnly: true);
  return rows.length;
});

/// Marcar como leído uno o todos; refresca la bandeja y la insignia.
class NoticeActions extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> markRead(String id) async {
    await ref.read(noticeRepositoryProvider).markRead(id);
    _refresh();
  }

  Future<int> markAllRead() async {
    final updated = await ref.read(noticeRepositoryProvider).markAllRead();
    _refresh();
    return updated;
  }

  void _refresh() {
    ref
      ..invalidate(noticesProvider)
      ..invalidate(unreadCountProvider);
  }
}

final noticeActionsProvider = AsyncNotifierProvider<NoticeActions, void>(
  NoticeActions.new,
);
