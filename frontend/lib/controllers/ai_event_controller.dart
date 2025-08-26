import 'dart:core';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:namer_app/models/calendar_event.dart';
import 'package:namer_app/models/generated_events.dart';
import 'package:namer_app/models/recurring_event.dart';
import 'package:namer_app/models/recurring_event_group.dart';
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
  GeneratedEvents _generatedEvents = GeneratedEvents(events: [], recurringEvents: []);
  bool _isProcessing = false;
  bool _isRecording = false;
  String _processingType = '';

  GeneratedEvents get generatedEvents => _generatedEvents;
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

  Future<void> processTextInput(String text) async {
    _setProcessingState(true, 'text');
    try {
      _generatedEvents = await AIEventService.processTextToEvent(text);
    } catch (e) {
      throw Exception('Failed to generate the events from the text: $e');
    } finally {
      _setProcessingState(false, '');
    }
  }

  Future<void> processImageInput(Uint8List imageBytes) async {
    _setProcessingState(true, 'image');
    try {
      // NOTE: We need the full image file's bytes here, not just the image data bytes,
      // so it's necessary to write to file then read again.
      final tempPath = 'temp.jpg';
      final cmd = img.Command()
        ..decodeImage(imageBytes)
        ..encodeJpg()
        ..writeToFile(tempPath);
      await cmd.executeThread();
      final tempFile = File(tempPath);
      final jpgImageBytes = await tempFile.readAsBytes();
      await tempFile.delete();
      _generatedEvents = await AIEventService.processImageToEvent(jpgImageBytes);
    } catch (e) {
      rethrow;
    } finally {
      _setProcessingState(false, '');
    }
  }

  Future<void> processAudioInput(String wavFilePath) async {
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
        _generatedEvents = await AIEventService.processAudioToEvent(audioData);

        // try to delete the temp files before we return
        try {
          outputFile.delete();
        } catch (e) { /* ignore */ }
        try {
          Uri inputPath = Uri.parse(wavFilePath);
          File inputFile = File.fromUri(inputPath);
          await inputFile.delete();
        } catch (e) { /* ignore */ }
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

  /// Submit the generated events.
  Future<void> saveGeneratedEvents() async {
    // TODO: this
  }

  /// Edit the calendar event at the index.
  void editEvent(int index, CalendarEvent updatedEvent) {
    if (index < _generatedEvents.events.length) {
      _generatedEvents.events[index] = updatedEvent;
    }
    notifyListeners();
  }

  /// Add the calendar event.
  void addEvent(CalendarEvent newEvent) {
    _generatedEvents.events.add(newEvent);
    notifyListeners();
  }

  /// Delete the calendar event at the index.
  void deleteEvent(int index) {
    if (index < _generatedEvents.events.length) {
      _generatedEvents.events.removeAt(index);
    }
    notifyListeners();
  }

  /// Edit the recurring event at the index.
  void editRecurringEvent(int index, RecurringEvent updatedEvent) {
    if (index < _generatedEvents.recurringEvents.length) {
      _generatedEvents.recurringEvents[index] = updatedEvent;
    }
    notifyListeners();
  }

  /// Add the calendar event.
  void addRecurringEvent(RecurringEvent newEvent) {
    _generatedEvents.recurringEvents.add(newEvent);
    notifyListeners();
  }

  /// Delete the recurring event at the index.
  void deleteRecurringEvent(int index) {
    if (index < _generatedEvents.recurringEvents.length) {
      _generatedEvents.recurringEvents.removeAt(index);
    }
    notifyListeners();
  }

  /// Set the recurring event group to the given value.
  void setRecurringEventGroup(RecurringEventGroup? group) {
    _generatedEvents.recurringEventGroup = group;
    notifyListeners();
  }

  /// Set the audio recording state.
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