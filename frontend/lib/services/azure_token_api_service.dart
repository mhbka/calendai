import 'package:http/http.dart' as http;
import 'package:calendai/main.dart';
import 'package:calendai/services/base_api_service.dart';

// For passing the user's Azure token the backend upon login,
// and ensuring it exists in the backend when already logged in.
class AzureTokenApiService extends BaseApiService {
  static String baseUrl = "${envVars.apiBaseUrl}/azure/token";

  // Send the user's Azure refresh token to the backend upon login.
  static Future<void> sendAzureToken() async {
    return BaseApiService.handleRequest(
      () => http.post(
        Uri.parse(baseUrl),
        headers: BaseApiService.headers,
      ), 
      (response) => ()
    );
  }

  // Verify that the backend has a valid Azure token stored for the user.
  // Usually called when the app starts with the user already logged in.
  static Future<void> verifyAzureTokenExists() async {
    return BaseApiService.handleRequest(
      () => http.get(
        Uri.parse(baseUrl),
        headers: BaseApiService.headers,
      ), 
      (response) => ()
    );
  }
}