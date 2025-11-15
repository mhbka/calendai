import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:namer_app/services/service_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Base class for API services with common error handling.
abstract class BaseApiService {
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
    'Azure-Refresh-Token': Supabase.instance.client.auth.currentSession?.providerRefreshToken ?? ''
  };

  /// Generic method to handle HTTP requests with consistent error handling
  static Future<T> handleRequest<T>(
    Future<http.Response> Function() request,
    T Function(http.Response) onSuccess, 
    {
      List<int> validStatusCodes = const [200],
    }
  ) async {
    try {
      final response = await request();
      if (validStatusCodes.contains(response.statusCode)) {
        return onSuccess(response);
      } else {
        throw ServiceException('Experienced a network error', response.statusCode);
      }
    } catch (e) {
      if (e is ServiceException) rethrow;
      throw ServiceException("Experienced an unexpected error: ${e.toString()}", -1);
    }
  }

  /// Helper for JSON parsing
  static List<T> parseJsonList<T>(String jsonString, T Function(Map<String, dynamic>) fromJson) {
    final jsonData = jsonDecode(jsonString) as List;
    return jsonData.map<T>((json) => fromJson(json)).toList();
  }
}