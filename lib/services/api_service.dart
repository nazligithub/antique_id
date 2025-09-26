import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;

  ApiService._internal() {
    _initDio();
  }

  void _initDio() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://helpful-farand-nazli-0d882cfe.koyeb.app',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'x-user-id': 'test-user-${DateTime.now().millisecondsSinceEpoch}',
      },
    ));

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
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
      throw ApiException('Could not scan antique', e);
    }
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
}

class ApiException implements Exception {
  final String message;
  final dynamic originalError;

  ApiException(this.message, this.originalError);

  @override
  String toString() => 'ApiException: $message';
}