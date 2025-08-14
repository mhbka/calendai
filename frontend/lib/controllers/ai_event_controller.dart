import 'dart:io';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:namer_app/models/calendar_event.dart';
import 'package:namer_app/models/generated_events.dart';
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

  Future<GeneratedEvents> processTextInput(String text) async {
    _setProcessingState(true, 'text');
    try {
      final events = await AIEventService.processTextToEvent(text);
      return events;
    } catch (e) {
      throw Exception('Failed to generate the events from the text: $e');
    } finally {
      _setProcessingState(false, '');
    }
  }

  Future<GeneratedEvents> processImageInput(Uint8List imageData) async {
    _setProcessingState(true, 'image');
    try {
      final events = await AIEventService.processImageToEvent(imageData);
      return events;
    } catch (e) {
      throw Exception('Failed to generate the events from the image: $e');
    } finally {
      _setProcessingState(false, '');
    }
  }

  Future<GeneratedEvents> processAudioInput(String wavFilePath) async {
    _setProcessingState(true, 'audio');
    try {
      // convert wav file to mp3
      final tempOutputPath = "temp.mp3";
      var session = await FFmpegKit.execute('ffmpeg -i $wavFilePath -vn -ar 44100 -ac 2 -b:a 128k $tempOutputPath');
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        // read mp3 file into memory, and send to service for processing
        Uri outputPathUri = Uri.parse(tempOutputPath);
        File outputFile = File.fromUri(outputPathUri);
        Uint8List audioData = await outputFile.readAsBytes();
        final events = await AIEventService.processAudioToEvent(audioData);

        // try to delete the temp files before we return
        try {
          outputFile.delete();
        } catch (e) { /* ignore */ }
        try {
          Uri inputPath = Uri.parse(wavFilePath);
          File inputFile = File.fromUri(inputPath);
          inputFile.delete();
        } catch (e) { /* ignore */ }

        return events;
      }
      else if (ReturnCode.isCancel(returnCode)) {
        throw ArgumentError("The audio processing was cancelled");
      }
      else {
        throw ArgumentError("The audio processing failed (ffmpeg code $returnCode)");
      }
    } 
    catch (e) {
      rethrow;
    } 
    finally {
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