import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import 'constants.dart';
import 'json_utils.dart';
import 'secure_storage.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.fieldErrors = const {}});

  final String message;
  final int? statusCode;
  final Map<String, String> fieldErrors;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// Klien HTTP tunggal dengan interceptor JWT otomatis.
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;
  String? _token;
  void Function()? onUnauthorized;

  bool get hasToken => (_token ?? '').isNotEmpty;

  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: const {'Accept': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (hasToken) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          final isLoginRequest = error.requestOptions.path.contains('/auth/login');
          if (error.response?.statusCode == 401 && !isLoginRequest) {
            _token = null;
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<void> loadToken() async {
    _token = await SecureStorage.getToken();
  }

  void setToken(String? token) {
    _token = token;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final response = await _guard(() => _dio.get(path, queryParameters: query));
    return _unwrap(response);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final response = await _guard(() => _dio.post(path, data: body));
    return _unwrap(response);
  }

  Future<dynamic> put(String path, {Object? body}) async {
    final response = await _guard(() => _dio.put(path, data: body));
    return _unwrap(response);
  }

  Future<dynamic> patch(String path, {Object? body}) async {
    final response = await _guard(() => _dio.patch(path, data: body));
    return _unwrap(response);
  }

  Future<dynamic> delete(String path) async {
    final response = await _guard(() => _dio.delete(path));
    return _unwrap(response);
  }

  Future<dynamic> postForm(String path, FormData form) async {
    final response = await _guard(() => _dio.post(path, data: form));
    return _unwrap(response);
  }

  Future<dynamic> putForm(String path, FormData form) async {
    final response = await _guard(() => _dio.put(path, data: form));
    return _unwrap(response);
  }

  /// Membentuk multipart file dari XFile (aman untuk Android, iOS, dan web).
  Future<MultipartFile> multipartFromXFile(XFile file) async {
    final bytes = await file.readAsBytes();
    final fileName = file.name.isEmpty ? 'upload.jpg' : file.name;
    final extension = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'jpg';
    final subtype = extension == 'jpg' ? 'jpeg' : extension;

    return MultipartFile.fromBytes(
      bytes,
      filename: fileName,
      contentType: DioMediaType('image', subtype),
    );
  }

  Future<Response<dynamic>> _guard(Future<Response<dynamic>> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw _mapDioError(error);
    } catch (_) {
      throw ApiException('Terjadi kesalahan tak terduga');
    }
  }

  dynamic _unwrap(Response<dynamic> response) {
    final data = response.data;

    if (data is Map) {
      final map = data.cast<String, dynamic>();
      if (map['success'] == false) {
        throw ApiException(
          asString(map['message'], fallback: 'Terjadi kesalahan'),
          statusCode: response.statusCode,
        );
      }
      return map['data'];
    }

    return data;
  }

  ApiException _mapDioError(DioException error) {
    final data = error.response?.data;
    Map<String, String> fieldErrors = {};
    String message = '';

    if (data is Map) {
      final map = data.cast<String, dynamic>();
      message = asString(map['message']);
      final errors = map['errors'];
      if (errors is List) {
        for (final item in errors) {
          if (item is Map) {
            final field = asString(item['field']);
            final detail = asString(item['message']);
            if (field.isNotEmpty) fieldErrors[field] = detail;
          }
        }
      }
    }

    if (message.isEmpty) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          message = AppStringsError.network;
          break;
        case DioExceptionType.cancel:
          message = 'Permintaan dibatalkan';
          break;
        default:
          message = AppStringsError.generic;
      }
    }

    return ApiException(
      message,
      statusCode: error.response?.statusCode,
      fieldErrors: fieldErrors,
    );
  }
}

/// Pesan fallback agar lapisan jaringan tidak bergantung pada BuildContext.
class AppStringsError {
  AppStringsError._();

  static const String network =
      'Tidak dapat terhubung ke server. Pastikan backend berjalan.';
  static const String generic = 'Terjadi kesalahan. Silakan coba lagi.';
}
