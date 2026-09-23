import 'package:dio/dio.dart';
import '../api_exception.dart';
import '../auth/token_store.dart';

const String defaultBaseUrl = 'http://localhost:3000';

class ApiClient {
  ApiClient({required this.tokenStore, String? baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? defaultBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )) {
    _addSessionInterceptor();
  }

  final TokenStore tokenStore;
  final Dio _dio;

  void Function()? onUnauthorized;

  Future<dynamic> getJson(String path) => _send(() => _dio.get(path));

  Future<dynamic> postJson(String path, {Object? body}) =>
      _send(() => _dio.post(path, data: body));

  Future<dynamic> patchJson(String path, {Object? body}) =>
      _send(() => _dio.patch(path, data: body));

  Future<void> postEmpty(String path) => _sendVoid(() => _dio.post(path));

  Future<void> delete(String path) => _sendVoid(() => _dio.delete(path));

  void _addSessionInterceptor() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStore.read();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final sentAuth =
            error.requestOptions.headers.containsKey('Authorization');
        if (error.response?.statusCode == 401 && sentAuth) {
          await tokenStore.delete();
          onUnauthorized?.call();
        }
        handler.next(error);
      },
    ));
  }

  Future<dynamic> _send(Future<Response<dynamic>> Function() run) async {
    try {
      return (await run()).data;
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<void> _sendVoid(Future<Response<dynamic>> Function() run) async {
    try {
      await run();
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException error) {
    final response = error.response;
    if (response == null) return ApiException.connection();
    return ApiException.fromNest(response.data, statusCode: response.statusCode);
  }
}
