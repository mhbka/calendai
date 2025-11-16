import 'package:http/http.dart' as http;
import 'package:namer_app/main.dart';
import 'package:namer_app/services/base_api_service.dart';

// For passing the user's Azure token the backend upon login,
// and ensuring it exists in the backend when already logged in.
class OutlookCalendarApiService extends BaseApiService {
  static String baseUrl = "${envVars.apiBaseUrl}/azure/calendar";

  // Triggers the syncing of this user's Outlook calendar with calendai.
  static Future<void> triggerSync() async {
    return BaseApiService.handleRequest(
      () => http.post(
        Uri.parse("$baseUrl/sync"),
        headers: BaseApiService.headers,
      ), 
      (response) => ()
    );
  }

  // Get the .ics file for this user's calendar events.
  static Future<String> getIcsFileContents() async {
    return BaseApiService.handleRequest(
      () => http.get(
        Uri.parse("$baseUrl/ics"),
        headers: BaseApiService.headers,
      ), 
      (response) => response.body
    );
  }
}