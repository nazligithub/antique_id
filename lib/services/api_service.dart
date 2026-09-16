import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  static const String _userIdKey = 'api_user_id';

  /// Only the scan endpoints get the long window: the server still falls back
  /// to answering a scan synchronously.
  static const Duration _scanTimeout = Duration(seconds: 180);

  late final Dio _dio;
  Future<String>? _userIdRequest;

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
        // The server writes the report in the language it is asked for and
        // falls back to English when it is not told, so every request says.
        options.headers['Accept-Language'] = Platform.localeName;
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
      throw _scanException(e);
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

  /// The server's error messages are English only, so the reader gets the
  /// app's own wording; the original response stays on the exception.
  ApiException _scanException(Object error) {
    if (error is DioException && error.type == DioExceptionType.cancel) {
      return ApiException(_cancelledMessage, error);
    }
    if (error is DioException && error.response != null) {
      return ApiException(
        switch (error.response!.statusCode) {
          // The only 400 a scan can earn: the photo showed no antique.
          400 => 'api_not_antique'.tr(),
          429 => 'api_too_many_requests'.tr(),
          _ => 'api_scan_failed'.tr(),
        },
        error,
      );
    }
    if (error is DioException &&
        (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout)) {
      return ApiException('api_timeout'.tr(), error);
    }
    return ApiException('api_scan_failed'.tr(), error);
  }

  /// Wording for a scan the server finished with `status: failed`.
  ///
  /// The reason arrives in English whatever the report language, so it is only
  /// used to tell a photo with no antique in it from everything else.
  static String scanFailureMessage(String? serverReason) {
    if (serverReason != null && serverReason.contains('upload antique image')) {
      return 'api_not_antique'.tr();
    }
    return 'api_scan_failed'.tr();
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