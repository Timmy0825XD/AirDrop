import '../../../core/network/api_client.dart';
import 'notice_models.dart';
import 'notice_repository.dart';

/// La bandeja contra Nest. No captura el error: `ApiClient` ya lanza
/// `ApiException` con el mensaje del servidor.
class RemoteNoticeRepository implements NoticeRepository {
  RemoteNoticeRepository({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<AppNotice>> list({bool unreadOnly = false}) async {
    final data = await apiClient.getJson(
      '/notifications',
      query: unreadOnly ? {'unread': 'true'} : null,
    );
    if (data is! List) {
      throw const FormatException('La bandeja no es una lista JSON.');
    }
    return [
      for (final row in data)
        if (row is Map) AppNotice.fromJson(Map<String, dynamic>.from(row)),
    ];
  }

  @override
  Future<AppNotice> markRead(String id) async {
    final data = await apiClient.patchJson('/notifications/$id/read');
    if (data is! Map) {
      throw const FormatException('El aviso no es un objeto JSON.');
    }
    return AppNotice.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<int> markAllRead() async {
    final data = await apiClient.postJson('/notifications/read-all');
    final updated = data is Map ? data['updated'] : null;
    return updated is num ? updated.toInt() : 0;
  }
}
