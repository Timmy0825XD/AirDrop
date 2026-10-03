import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../api_exception.dart';
import '../auth/token_store.dart';

/// En el emulador de Android, `localhost` es el propio emulador.
/// `10.0.2.2` es el alias que el emulador usa para llegar al PC.
///
/// En web `Platform` no existe y lanza `Unsupported operation:
/// Platform._operatingSystem`, así que `kIsWeb` se decide antes de tocarlo.
String get defaultBaseUrl => kIsWeb
    ? 'http://localhost:3000'
    : (Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000');

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

  /// Lee un recurso. [query] se envía como query string; los valores que
  /// sean `null` se omiten, así el backend puede distinguir "sin filtro" de
  /// "filtro vacío".
  Future<dynamic> getJson(String path, {Map<String, String>? query}) =>
      _send(() => _dio.get(path, queryParameters: query));

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
