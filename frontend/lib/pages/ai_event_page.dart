import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:namer_app/models/calendar_event.dart';
import 'package:namer_app/widgets/audio_recorder.dart';
import 'package:namer_app/widgets/event_dialog.dart';
import 'package:namer_app/widgets/processing_indicator.dart';
import 'package:namer_app/widgets/event_input.dart';
import 'package:namer_app/widgets/example_tip.dart';
import 'package:namer_app/controllers/calendar_controller.dart';
import 'package:namer_app/controllers/ai_event_controller.dart';

class AddEventPage extends StatefulWidget {
  final CalendarController? calendarController;

  const AddEventPage({
    Key? key,
    this.calendarController,
  }) : super(key: key);

  @override
  _AddEventPageState createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  late AddEventController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AddEventController(calendarController: widget.calendarController);
    _controller.addListener(_onControllerStateChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerStateChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerStateChanged() {
    setState(() {});
  }

  Future<void> _handlePaste() async {
    try {
      final text = await _controller.handlePaste();
      if (text != null) {
        await _processTextInput(text);
      } else {
        _showSnackBar('No text found in clipboard');
      }
    } catch (e) {
      _showSnackBar(e.toString());
    }
  }

  Future<void> _processTextInput(String text) async {
    try {
      final event = await _controller.processTextInput(text);
      await _showEventPreview(event);
    } catch (e) {
      _showErrorDialog('Processing Error', e.toString());
    }
  }

  Future<void> _processAudioInput(Uint8List audioData) async {
    try {
      final event = await _controller.processAudioInput(audioData);
      await _showEventPreview(event);
    } catch (e) {
      _showErrorDialog('Audio Processing Error', e.toString());
    }
  }

  Future<void> _showEventPreview(CalendarEvent event) async {
    await showDialog(
      context: context,
      builder: (context) => EventDialog(
        event: event,
        selectedDay: event.startTime,
        onSave: _saveGeneratedEvent,
      ),
    );
  }

  Future<void> _saveGeneratedEvent(
    CalendarEvent? existingEvent,
    String title,
    String description,
    String? location,
    DateTime startTime,
    DateTime endTime,
  ) async {
    Navigator.pop(context);
    
    try {
      await _controller.saveGeneratedEvent(
        existingEvent: existingEvent,
        title: title,
        description: description,
        location: location,
        startTime: startTime,
        endTime: endTime,
      );

      if (_controller.hasCalendarController) {
        _showSnackBar('Event created successfully!');
        Navigator.pop(context);
      } else {
        _showSnackBar('Event preview completed');
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorDialog('Save Error', 'Failed to save event: $e');
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        icon: Icon(Icons.error_outline, color: Colors.red, size: 48),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildMainArea() {
    if (_controller.isProcessing) {
      return ProcessingIndicatorWidget(
        processingType: _controller.processingType,
      );
    }

    if (_controller.isRecording) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red, width: 2),
          borderRadius: BorderRadius.circular(12),
          color: Colors.red[50],
        ),
        child: AudioRecorder(
          onRecordingComplete: _processAudioInput,
          onRecordingStart: () => _controller.setRecording(true),
          onRecordingStop: () => _controller.setRecording(false),
        ),
      );
    }

    return EventInputWidget(
      onPaste: _handlePaste,
      onStartRecording: () => _controller.setRecording(true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Add Event'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 64,
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(height: 24),
              Text(
                'Create a calendar event with AI',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Paste text or record audio to automatically generate a calendar event',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 48),
              _buildMainArea(),
              SizedBox(height: 30),
              if (!_controller.isProcessing && !_controller.isRecording) 
                ExampleTipWidget(),
            ],
          ),
        ),
      ),
    );
  }
}