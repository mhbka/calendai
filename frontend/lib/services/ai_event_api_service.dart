import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:namer_app/main.dart';
import 'package:namer_app/models/generated_events.dart';
import 'package:namer_app/services/base_api_service.dart';

// For interacting with the AI Event API.
class AIEventService extends BaseApiService {
  static String baseUrl = "${envVars.apiBaseUrl}/ai_add_event";

  /// We include our local timezone's offset, so the backend can offset generated events' datetimes from UTC for usability.
  static int timezoneOffsetInMinutes = DateTime.now().timeZoneOffset.inMinutes;

  /// Generate events from text.
  static Future<GeneratedEvents> processTextToEvent(String text) async {
    return BaseApiService.handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/text'),
        headers: BaseApiService.headers,
        body: json.encode({
          'text': text, 
          'timezone_offset_minutes': timezoneOffsetInMinutes
        }),
      ),
      (response) => GeneratedEvents.fromJson(json.decode(response.body)),
      validStatusCodes: [200, 201],
    );
  }

  /// Generate events from audio.
  static Future<GeneratedEvents> processAudioToEvent(Uint8List mp3AudioData) async {
    return BaseApiService.handleRequest(
      () async {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/audio'),
        );
        request.files.add(
          http.MultipartFile.fromBytes(
            'audio', 
            mp3AudioData,
            filename: 'audio.mp3',
            contentType: MediaType('audio', 'mpeg'),
          ),
        );
        request.headers.addAll(BaseApiService.headers);
        request.fields.addAll({'timezone_offset_minutes': timezoneOffsetInMinutes.toString()});
        return await request
          .send()
          .then((streamedResponse) async {
            return await http.Response.fromStream(streamedResponse);
          });
      },
      (response) => GeneratedEvents.fromJson(json.decode(response.body)),
      validStatusCodes: [200, 201],
    );
  }

  /// Generate events from an image.
  static Future<GeneratedEvents> processImageToEvent(Uint8List imageData) async {
    return BaseApiService.handleRequest(
      () async {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/image'),
        );
        String filename = 'image.jpg';
        MediaType contentType = MediaType('image', 'jpeg');
        request.headers.addAll(BaseApiService.headers);
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageData,
            filename: filename,
            contentType: contentType,
          ),
        );
        request.fields.addAll({'timezone_offset_minutes': timezoneOffsetInMinutes.toString()});
        return await request
          .send()
          .then((streamedResponse) async {
            return await http.Response.fromStream(streamedResponse);
          });
      },
      (response) => GeneratedEvents.fromJson(json.decode(response.body)),
      validStatusCodes: [200, 201],
    );
  }
}