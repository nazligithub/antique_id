import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  static const String _userIdKey = 'api_user_id';

  late final Dio _dio;
  Future<String>? _userIdRequest;

  ApiService._internal() {
    _initDio();
  }

  void _initDio() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://pkkkg088wooowow0coogks08.mobinaz.work',
      connectTimeout: const Duration(seconds: 30),
      // Covers the synchronous scan path, which servers still fall back to.
      receiveTimeout: const Duration(seconds: 180),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        options.headers['x-user-id'] = await _userId();
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
    final random = Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return 'user-${DateTime.now().millisecondsSinceEpoch}-$random';
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

      final response = await _dio.post('/api/scan/antique', data: formData);
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
  Future<Map<String, dynamic>> startScan(String imagePath,
      {String? additionalInfo}) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath),
        'async': 'true',
        if (additionalInfo != null) 'additionalInfo': additionalInfo,
      });

      final response = await _dio.post('/api/scan/antique', data: formData);
      return response.data;
    } catch (e) {
      throw _scanException(e);
    }
  }

  Future<Map<String, dynamic>> getScanStatus(dynamic scanId) async {
    try {
      final response = await _dio.get('/api/scan/$scanId/status');
      return response.data;
    } catch (e) {
      throw _scanException(e);
    }
  }

  ApiException _scanException(Object error) {
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

class ApiException implements Exception {
  final String message;
  final dynamic originalError;

  ApiException(this.message, this.originalError);

  @override
  String toString() => 'ApiException: $message';
}