import '../../../../core/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../auth/data/auth_models.dart';
import 'user_models.dart';
import 'user_repository.dart';

/// Las tres operaciones contra Nest (`UsersController`, solo `admin`).
/// Todos los errores se relanzan como [ApiException] para que la UI
/// muestre el mensaje que define el backend.
class RemoteUserRepository implements UserRepository {
  RemoteUserRepository({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<PublicUser>> list({UserRole? role, UserStatus? status}) async {
    final data = await apiClient.getJson(
      '/users',
      query: {
        if (role != null) 'role': role.apiValue,
        if (status != null) 'status': status.apiValue,
      },
    );
    return _asJsonList(data)
        .map((row) => PublicUser.fromJson(_asJsonMap(row)))
        .toList(growable: false);
  }

  @override
  Future<PublicUser> create(CreateUserRequest request) async {
    final data = await apiClient.postJson('/users', body: request.toJson());
    return PublicUser.fromJson(_asJsonMap(data));
  }

  @override
  Future<PublicUser> setSuspension(String id, {required bool suspended}) async {
    final data = await apiClient.patchJson(
      '/users/$id/suspension',
      body: {'suspended': suspended},
    );
    return PublicUser.fromJson(_asJsonMap(data));
  }

  Map<String, dynamic> _asJsonMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map<Object?, Object?>) return Map<String, dynamic>.from(data);
    throw const FormatException('La respuesta del usuario no es un objeto JSON.');
  }

  List<Object?> _asJsonList(Object? data) {
    if (data is List<Object?>) return data;
    throw const FormatException('La respuesta de los usuarios no es una lista JSON.');
  }
}
