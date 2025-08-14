import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:namer_app/models/calendar_event.dart';
import 'package:namer_app/pages/ai_event_page/ai_event_body.dart';
import 'package:namer_app/pages/base_page.dart';
import 'package:namer_app/utils/alerts.dart';
import 'package:namer_app/widgets/event_dialog.dart';
import 'package:namer_app/controllers/calendar_controller.dart';
import 'package:namer_app/controllers/ai_event_controller.dart';

class AddAIEventPage extends StatefulWidget {
  final CalendarController calendarController = CalendarController.instance;

  AddAIEventPage({super.key});

  @override
  _AddAIEventPageState createState() => _AddAIEventPageState();
}

class _AddAIEventPageState extends State<AddAIEventPage> {
  late final AddAIEventController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AddAIEventController.instance;
    _controller.addListener(_onControllerStateChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerStateChanged);
    super.dispose();
  }

  void _onControllerStateChanged() {
    setState(() {});
  }

  /// Handles the pasting of the user's clipboard + processing of text into a calendar event.
  Future<void> _handlePaste() async {
    try {
      final text = await _controller.handlePaste();
      if (text != null) {
        await _processTextInput(text);
      } else {
        Alerts.showErrorSnackBar(context, "There was no text/image in your clipboard. Please copy your intended media and try again.");
      }
    } catch (e) {
      Alerts.showErrorSnackBar(context, "Failed to obtain your pasted text/image: $e. Please try again.");
    }
  }

  Future<void> _processTextInput(String text) async {
    try {
      final event = await _controller.processTextInput(text);
      //await _showEventPreview(event);
      Alerts.showInfoSnackBar(context, "all good OG");
    } catch (e) {
      Alerts.showErrorDialog(
        context,
        "Error",
        "Failed to process the text input: $e. Please try again."
      );
    }
  }

  Future<void> _processAudioInput(String wavFilePath) async {
    try {
      final event = await _controller.processAudioInput(wavFilePath);
      // await _showEventPreview(event);
      Alerts.showInfoSnackBar(context, "all good OG");
    } catch (e) {
      Alerts.showErrorDialog(
        context,
        "Error",
        "Failed to process the audio: $e. Please try again."
      );
    }
  }

  Future<void> _showEventPreview(CalendarEvent event) async {
    await showDialog(
      context: context,
      builder: (context) => EventDialog(
        event: event,
        selectedDay: event.startTime,
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  return BasePage(
    title: 'Add event with AI',
    body: AIEventBody(
      controller: _controller, 
      handlePaste: _handlePaste, 
      onRecordingComplete: _processAudioInput
      ),
  );
}
}