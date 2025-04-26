import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/api_logger.dart';

class ApiService {
  static const _timeoutDuration = Duration(seconds: 30);

  static Future<Map<String, dynamic>> post({
    required String endpoint,
    required Map<String, dynamic> body,
    String? token,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}$endpoint';
      final headers = ApiConfig.getHeaders(token: token);

      // Log the request
      ApiLogger.logRequest(
        method: 'POST',
        url: url,
        headers: headers,
        body: body,
      );

      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_timeoutDuration);

      // Log the response
      ApiLogger.logResponse(
        statusCode: response.statusCode,
        headers: response.headers,
        body: jsonDecode(response.body),
      );

      if (response.statusCode == ApiConfig.success ||
          response.statusCode == ApiConfig.created) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to make POST request: ${response.body}');
      }
    } on http.ClientException catch (e) {
      ApiLogger.logError(error: e.toString(), stackTrace: StackTrace.current);
      throw Exception(ApiConfig.networkError);
    } catch (e, stackTrace) {
      ApiLogger.logError(error: e.toString(), stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> get({
    required String endpoint,
    String? token,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}$endpoint';
      final headers = ApiConfig.getHeaders(token: token);

      // Log the request
      ApiLogger.logRequest(
        method: 'GET',
        url: url,
        headers: headers,
        body: {},
      );

      final response = await http
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(_timeoutDuration);

      // Log the response
      ApiLogger.logResponse(
        statusCode: response.statusCode,
        headers: response.headers,
        body: jsonDecode(response.body),
      );

      if (response.statusCode == ApiConfig.success) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to make GET request: ${response.body}');
      }
    } on http.ClientException catch (e) {
      ApiLogger.logError(error: e.toString(), stackTrace: StackTrace.current);
      throw Exception(ApiConfig.networkError);
    } catch (e, stackTrace) {
      ApiLogger.logError(error: e.toString(), stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> put({
    required String endpoint,
    required Map<String, dynamic> body,
    String? token,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}$endpoint';
      final headers = ApiConfig.getHeaders(token: token);

      // Log the request
      ApiLogger.logRequest(
        method: 'PUT',
        url: url,
        headers: headers,
        body: body,
      );

      final response = await http
          .put(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_timeoutDuration);

      // Log the response
      ApiLogger.logResponse(
        statusCode: response.statusCode,
        headers: response.headers,
        body: jsonDecode(response.body),
      );

      if (response.statusCode == ApiConfig.success) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to make PUT request: ${response.body}');
      }
    } on http.ClientException catch (e) {
      ApiLogger.logError(error: e.toString(), stackTrace: StackTrace.current);
      throw Exception(ApiConfig.networkError);
    } catch (e, stackTrace) {
      ApiLogger.logError(error: e.toString(), stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> delete({
    required String endpoint,
    String? token,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}$endpoint';
      final headers = ApiConfig.getHeaders(token: token);

      // Log the request
      ApiLogger.logRequest(
        method: 'DELETE',
        url: url,
        headers: headers,
        body: {},
      );

      final response = await http
          .delete(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(_timeoutDuration);

      // Log the response
      ApiLogger.logResponse(
        statusCode: response.statusCode,
        headers: response.headers,
        body: jsonDecode(response.body),
      );

      if (response.statusCode == ApiConfig.success) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to make DELETE request: ${response.body}');
      }
    } on http.ClientException catch (e) {
      ApiLogger.logError(error: e.toString(), stackTrace: StackTrace.current);
      throw Exception(ApiConfig.networkError);
    } catch (e, stackTrace) {
      ApiLogger.logError(error: e.toString(), stackTrace: stackTrace);
      rethrow;
    }
  }
}
