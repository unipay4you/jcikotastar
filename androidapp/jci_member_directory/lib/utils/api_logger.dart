import 'dart:convert';
import 'package:flutter/foundation.dart';

class ApiLogger {
  static void logRequest({
    required String method,
    required String url,
    required Map<String, String> headers,
    required dynamic body,
  }) {
    if (kDebugMode) {
      print('\n=== API Request ===');
      print('Method: $method');
      print('URL: $url');
      print('Headers: ${jsonEncode(headers)}');
      print('Body: ${jsonEncode(body)}');
      print('==================\n');
    }
  }

  static void logResponse({
    required int statusCode,
    required Map<String, String> headers,
    required dynamic body,
  }) {
    if (kDebugMode) {
      print('\n=== API Response ===');
      print('Status Code: $statusCode');
      print('Headers: ${jsonEncode(headers)}');
      print('Body: ${jsonEncode(body)}');
      print('===================\n');
    }
  }

  static void logError({
    required String error,
    required StackTrace stackTrace,
  }) {
    if (kDebugMode) {
      print('\n=== API Error ===');
      print('Error: $error');
      print('Stack Trace: $stackTrace');
      print('================\n');
    }
  }

  static void logProgress({
    required String message,
    required double progress,
  }) {
    if (kDebugMode) {
      print('\n=== API Progress ===');
      print('Message: $message');
      print('Progress: ${(progress * 100).toStringAsFixed(2)}%');
      print('===================\n');
    }
  }
}
