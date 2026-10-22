import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../../data/services/token_service.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await TokenService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> get(String endpoint, {bool requiresAuth = true}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders(requiresAuth: requiresAuth);

    final response = await http.get(uri, headers: headers).timeout(
      const Duration(seconds: 15),
    );

    return _processResponse(response);
  }

  Future<dynamic> post(String endpoint, dynamic body, {bool requiresAuth = true}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders(requiresAuth: requiresAuth);

    final response = await http
        .post(uri, headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));

    return _processResponse(response);
  }

  Future<dynamic> put(String endpoint, dynamic body, {bool requiresAuth = true}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders(requiresAuth: requiresAuth);

    final response = await http
        .put(uri, headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));

    return _processResponse(response);
  }

  dynamic _processResponse(http.Response response) {
    try {
      final utf8Body = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> json = jsonDecode(utf8Body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json['data'];
      } else {
        final message = json['message'] ?? 'Đã xảy ra lỗi (${response.statusCode})';
        throw ApiException(response.statusCode, message);
      }
    } on FormatException {
      throw ApiException(response.statusCode, 'Lỗi phản hồi từ máy chủ (${response.statusCode})');
    }
  }
}
