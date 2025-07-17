import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:namer_app/main.dart';
import 'package:namer_app/models/calendar_event.dart';
import 'package:namer_app/services/base_api_service.dart';
// For interacting with the AI Event API.
class AIEventService extends BaseApiService {
  static String baseUrl = "${envVars['api_base_url']!}/add_ai_event";

  /// Generate an event from text.
  static Future<CalendarEvent> processTextToEvent(String text) async {
    return BaseApiService.handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/text'),
        headers: BaseApiService.headers,
        body: json.encode({'text': text}),
      ),
      (response) => CalendarEvent.fromJson(json.decode(response.body)),
      validStatusCodes: [200, 201],
    );
  }

  /// Generate an event from audio.
  static Future<CalendarEvent> processAudioToEvent(Uint8List audioData) async {
    return BaseApiService.handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/audio'),
        headers: {
          'Content-Type': 'application/octet-stream',
          'Accept': 'application/json',
        },
        body: audioData,
      ),
      (response) => CalendarEvent.fromJson(json.decode(response.body)),
      validStatusCodes: [200, 201],
    );
  }
}