import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:namer_app/main.dart';
import 'package:namer_app/models/generated_events.dart';
import 'package:namer_app/services/base_api_service.dart';

// For interacting with the AI Event API.
class AIEventService extends BaseApiService {
  static String baseUrl = "${envVars['api_base_url']!}/ai_add_event";

  /// Generate events from text.
  static Future<GeneratedEvents> processTextToEvent(String text) async {
    return BaseApiService.handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/text'),
        headers: BaseApiService.headers,
        body: json.encode({'text': text}),
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
        // Determine image format and add to multipart form
        String filename;
        MediaType contentType;
        if (_isPng(imageData)) {
          filename = 'image.png';
          contentType = MediaType('image', 'png');
        } 
        else if (_isJpeg(imageData)) {
          filename = 'image.jpg';
          contentType = MediaType('image', 'jpeg');
        } 
        else {
          // Default to PNG if format cannot be determined
          filename = 'image.png';
          contentType = MediaType('image', 'png');
        }

        request.files.add(
          http.MultipartFile.fromBytes(
            'image', // field name
            imageData,
            filename: filename,
            contentType: contentType,
          ),
        );

        return await request.send().then((streamedResponse) async {
          return await http.Response.fromStream(streamedResponse);
        });
      },
      (response) => GeneratedEvents.fromJson(json.decode(response.body)),
      validStatusCodes: [200, 201],
    );
  }

  /// Check if image data is PNG format.
  static bool _isPng(Uint8List imageData) {
    if (imageData.length < 8) return false;
    return imageData[0] == 0x89 &&
           imageData[1] == 0x50 &&
           imageData[2] == 0x4E &&
           imageData[3] == 0x47 &&
           imageData[4] == 0x0D &&
           imageData[5] == 0x0A &&
           imageData[6] == 0x1A &&
           imageData[7] == 0x0A;
  }

  /// Check if image data is JPEG format.
  static bool _isJpeg(Uint8List imageData) {
    if (imageData.length < 2) return false;
    return imageData[0] == 0xFF && imageData[1] == 0xD8;
  }
}

// You'll need to add this import at the top of your file:
// import 'package:http_parser/http_parser.dart';