import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:namer_app/models/calendar_event.dart';
import 'package:namer_app/services/ai_event_api_service.dart';
import 'package:namer_app/controllers/calendar_controller.dart';

class AddAIEventController extends ChangeNotifier {
  // singleton stuff
  AddAIEventController._internal() {
    _calendarController = CalendarController.instance;
  }

  static final AddAIEventController _instance = AddAIEventController._internal();

  factory AddAIEventController() {
    return _instance;
  }

  static AddAIEventController get instance => _instance;

  late final CalendarController? _calendarController;
  
  // members
  bool _isProcessing = false;
  bool _isRecording = false;
  String _processingType = '';

  bool get isProcessing => _isProcessing;
  bool get isRecording => _isRecording;
  String get processingType => _processingType;
  
  // methods
  Future<String?> handlePaste() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null && clipboardData!.text!.trim().isNotEmpty) {
        return clipboardData.text!.trim();
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Failed to paste from clipboard');
    }
  }

  Future<CalendarEvent> processTextInput(String text) async {
    _setProcessingState(true, 'text');
    
    try {
      final event = await AIEventService.processTextToEvent(text);
      return event;
    } catch (e) {
      throw Exception('Processing Error: ${e.toString()}');
    } finally {
      _setProcessingState(false, '');
    }
  }

  Future<CalendarEvent> processAudioInput(Uint8List audioData) async {
    _setProcessingState(true, 'audio');

    try {
      final event = await AIEventService.processAudioToEvent(audioData);
      return event;
    } catch (e) {
      throw Exception('Audio Processing Error: ${e.toString()}');
    } finally {
      _setProcessingState(false, '');
      setRecording(false);
    }
  }

  Future<void> saveGeneratedEvent({
    CalendarEvent? existingEvent,
    required String title,
    required String description,
    String? location,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    if (_calendarController != null) {
      // TODO: think this API will be changed/deleted
      /*
      await _calendarController!.saveEvent(
        existingEvent: existingEvent,
        title: title,
        description: description,
        location: location,
        startTime: startTime,
        endTime: endTime,
      );
      */
    }
  }

  void setRecording(bool recording) {
    _isRecording = recording;
    notifyListeners();
  }

  void _setProcessingState(bool processing, String type) {
    _isProcessing = processing;
    _processingType = type;
    notifyListeners();
  }

  bool get hasCalendarController => _calendarController != null;
}