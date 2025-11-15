import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:namer_app/main.dart';
import 'package:namer_app/models/generated_events.dart';
import 'package:namer_app/models/outlook_email.dart';
import 'package:namer_app/services/base_api_service.dart';

/// For interacting with the backend's Outlook email API.
class OutlookEmailApiService extends BaseApiService {
  static String baseUrl = "${envVars.apiBaseUrl}/azure/email";

  /// Check `AiEventApiService` for reasoning
  static int timezoneOffsetInMinutes = DateTime.now().timeZoneOffset.inMinutes;

  /// Fetch the user's emails.
  static Future<List<OutlookEmailMessage>> fetchUserEmails() async {
    return BaseApiService.handleRequest(
      () => http.get(
        Uri.parse("$baseUrl/fetch_user_emails"),
        headers: BaseApiService.headers,
        ),
      (response) => BaseApiService.parseJsonList(response.body, OutlookEmailMessage.fromJson) 
    );
  }

  /// Generate events from the Outlook email denoted by the given `mailId`.
  static Future<GeneratedEvents> generateEventsFromEmail(String mailId) async {
    return BaseApiService.handleRequest(
      () => http.get(
        Uri
          .parse("$baseUrl/fetch_user_emails")
          .replace(queryParameters: {
            'mail_id': mailId,
            'timezone_offset_minutes': timezoneOffsetInMinutes
          }),
        headers: BaseApiService.headers,
        ),
      (response) => GeneratedEvents.fromJson(json.decode(response.body))
    );
  }
}