import 'dart:convert';
import 'dart:typed_data';
import 'package:namer_app/main.dart';
import 'package:namer_app/models/calendar_event.dart';

class AIEventService {
  static String baseUrl = envVars['api_base_url']!;

  /// Process text input to generate a CalendarEvent
  /// TODO: Stub implementation - replace with actual API call
  static Future<CalendarEvent> processTextToEvent(String text) async {
    try {
      // Mock response - replace with actual API response parsing
      if (text.toLowerCase().contains('error')) {
        throw Exception('Failed to parse event from text');
      }
    
      final mockEvent = CalendarEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _extractTitle(text),
        description: _extractDescription(text),
        location: _extractLocation(text),
        startTime: _extractStartTime(text),
        endTime: _extractEndTime(text),
      );
      
      return mockEvent;
    } catch (e) {
      throw Exception('Error processing text: ${e.toString()}');
    }
  }

  /// Process audio recording to generate a CalendarEvent
  /// TODO: Stub implementation - replace with actual API call
  static Future<CalendarEvent> processAudioToEvent(Uint8List audioData) async {
    try {
      final mockTranscribedText = "Meeting with client tomorrow at 2 PM for project discussion";
      
      final mockEvent = CalendarEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: "Meeting with client",
        description: "Project discussion",
        location: null,
        startTime: DateTime.now().add(Duration(days: 1)).copyWith(hour: 14, minute: 0),
        endTime: DateTime.now().add(Duration(days: 1)).copyWith(hour: 15, minute: 0),
      );
      
      return mockEvent;
    } catch (e) {
      throw Exception('Error processing audio: ${e.toString()}');
    }
  }

  // Mock helper methods for text parsing - replace with actual AI processing
  static String _extractTitle(String text) {
    // Simple mock extraction - in reality, this would be done by AI
    final words = text.split(' ');
    if (words.length > 3) {
      return words.take(3).join(' ');
    }
    return words.first;
  }

  static String _extractDescription(String text) {
    return text.length > 50 ? text.substring(0, 50) + '...' : text;
  }

  static String? _extractLocation(String text) {
    if (text.toLowerCase().contains('at ') || text.toLowerCase().contains('in ')) {
      return "Conference Room A"; // Mock location
    }
    return null;
  }

  static DateTime _extractStartTime(String text) {
    // Mock time extraction - in reality, this would be done by AI
    final now = DateTime.now();
    if (text.toLowerCase().contains('tomorrow')) {
      return now.add(Duration(days: 1)).copyWith(hour: 10, minute: 0);
    } else if (text.toLowerCase().contains('next week')) {
      return now.add(Duration(days: 7)).copyWith(hour: 10, minute: 0);
    }
    return now.add(Duration(hours: 1)).copyWith(minute: 0);
  }

  static DateTime _extractEndTime(String text) {
    final startTime = _extractStartTime(text);
    return startTime.add(Duration(hours: 1));
  }
}