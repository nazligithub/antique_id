import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  static const String _userIdKey = 'api_user_id';

  /// Presented as `x-api-key`. This is not a secret in any strong sense -- it
  /// ships inside the binary and anyone willing to unpack the app can read it
  /// out. What it buys is that knowing the URL is no longer enough to spend
  /// the scan budget, which is the abuse that actually happens.
  static const String _apiKey =
      'ak_1117b6c0f872589ba0e453476855fc558d761710ebee9289';

  /// Only the scan endpoints get the long window: the server still falls back
  /// to answering a scan synchronously.
  static const Duration _scanTimeout = Duration(seconds: 180);

  late final Dio _dio;
  Future<String>? _userIdRequest;
  Future<String>? _appVersionRequest;

  ApiService._internal() {
    _initDio();
  }

  void _initDio() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://pkkkg088wooowow0coogks08.mobinaz.work',
      connectTimeout: const Duration(seconds: 30),
      // Everything but a scan answers quickly. This used to sit at 180s for
      // every call, so a stalled chat or history request left the reader
      // staring at a spinner for three minutes.
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        options.headers['x-user-id'] = await _userId();
        options.headers['x-api-key'] = _apiKey;
        options.headers['x-app-version'] = await _appVersion();
        handler.next(options);
      },
    ));

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
  }

  /// The release the caller is running, sent so the server can tell an old
  /// build apart from an unknown caller. Both arrive without a valid key while
  /// the gate is in report-only mode, and only this header says which is which.
  Future<String> _appVersion() {
    return _appVersionRequest ??= _loadAppVersion();
  }

  Future<String> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } catch (error) {
      debugPrint('Could not read app version: $error');
      return 'unknown';
    }
  }

  /// A stable per-install identifier.
  ///
  /// This used to be regenerated on every launch, which made the server treat
  /// each session as a brand new user and left scan history permanently empty.
  Future<String> _userId() {
    return _userIdRequest ??= _loadUserId();
  }

  Future<String> _loadUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_userIdKey);
      if (stored != null && stored.isNotEmpty) return stored;

      final created = _newUserId();
      await prefs.setString(_userIdKey, created);
      return created;
    } catch (_) {
      // Storage unavailable: stay usable for this session rather than failing.
      return _newUserId();
    }
  }

  String _newUserId() {
    // Secure, and wider than the old 24 bits: the server trusts this header as
    // the caller's identity, so a guessable id is a guessable account.
    final random = Random.secure();
    final suffix = List.generate(
      4,
      (_) => random.nextInt(0x10000).toRadixString(16).padLeft(4, '0'),
    ).join();
    return 'user-${DateTime.now().millisecondsSinceEpoch}-$suffix';
  }

  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      return response.data;
    } catch (e) {
      throw ApiException('Health check failed', e);
    }
  }

  Future<Map<String, dynamic>> scanAntique(String imagePath, {String? additionalInfo}) async {
    try {
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath),
        if (additionalInfo != null) 'additionalInfo': additionalInfo,
      });

      final response = await _dio.post(
        '/api/scan/antique',
        data: formData,
        options: Options(receiveTimeout: _scanTimeout),
      );
      return response.data;
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final errorData = e.response!.data;
        String errorMessage = 'Could not scan antique';

        if (errorData is Map<String, dynamic>) {
          errorMessage = errorData['message'] ?? errorMessage;
        }

        throw ApiException(errorMessage, e);
      }
      throw ApiException('Could not scan antique', e);
    }
  }

  /// Starts a scan and returns as soon as the server has accepted it.
  ///
  /// Returns either `{status: 'processing', scan_id: ...}` to poll with
  /// [getScanStatus], or a finished result when the server had to fall back to
  /// the synchronous path.
  Future<Map<String, dynamic>> startScan(
    String imagePath, {
    String? additionalInfo,
    CancelToken? cancelToken,
  }) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath),
        'async': 'true',
        if (additionalInfo != null) 'additionalInfo': additionalInfo,
      });

      final response = await _dio.post(
        '/api/scan/antique',
        data: formData,
        cancelToken: cancelToken,
        options: Options(receiveTimeout: _scanTimeout),
      );
      return response.data;
    } catch (e) {
      throw _scanException(e);
    }
  }

  Future<Map<String, dynamic>> getScanStatus(
    dynamic scanId, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        '/api/scan/$scanId/status',
        cancelToken: cancelToken,
      );
      return response.data;
    } catch (e) {
      throw _scanException(e);
    }
  }

  ApiException _scanException(Object error) {
    if (error is DioException && error.type == DioExceptionType.cancel) {
      return ApiException(_cancelledMessage, error);
    }
    if (error is DioException && error.response?.data is Map<String, dynamic>) {
      final data = error.response!.data as Map<String, dynamic>;
      return ApiException(data['message'] ?? 'Could not scan antique', error);
    }
    if (error is DioException &&
        (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout)) {
      return ApiException('The connection timed out. Please try again.', error);
    }
    return ApiException('Could not scan antique', error);
  }

  Future<Map<String, dynamic>> getHistory({int limit = 20, int offset = 0}) async {
    try {
      final response = await _dio.get('/api/scan/history',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        }
      );
      return response.data;
    } catch (e) {
      throw ApiException('Could not get scan history', e);
    }
  }

  Future<Map<String, dynamic>> getScanDetails(String scanId) async {
    try {
      final response = await _dio.get('/api/scan/$scanId');
      return response.data;
    } catch (e) {
      throw ApiException('Could not get scan details', e);
    }
  }

  Future<Map<String, dynamic>> getAntiquesList({int limit = 50}) async {
    try {
      final response = await _dio.get('/api/antiques/list',
        queryParameters: {
          'limit': limit,
        }
      );
      return response.data;
    } catch (e) {
      throw ApiException('Could not get antiques list', e);
    }
  }

  Future<Map<String, dynamic>> chatWithAI(String message, String scanId) async {
    try {
      final response = await _dio.post('/api/chat', data: {
        'message': message,
        'scanId': scanId,
      });
      return response.data;
    } catch (e) {
      throw ApiException('Could not send message', e);
    }
  }

  Future<Map<String, dynamic>> chatWithExpert(String message) async {
    try {
      final response = await _dio.post('/api/chat', data: {
        'message': message,
        'context': 'antique_expert',
      });
      return response.data;
    } catch (e) {
      throw ApiException('Could not chat with expert', e);
    }
  }
}

/// Marks a request the app itself called off, so callers can stay silent
/// instead of showing the reader an error they caused by leaving the screen.
const String _cancelledMessage = 'Scan cancelled';

class ApiException implements Exception {
  final String message;
  final dynamic originalError;

  ApiException(this.message, this.originalError);

  bool get wasCancelled => message == _cancelledMessage;

  @override
  String toString() => 'ApiException: $message';
}