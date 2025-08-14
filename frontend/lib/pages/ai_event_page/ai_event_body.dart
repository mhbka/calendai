import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:namer_app/controllers/ai_event_controller.dart';
import 'package:namer_app/widgets/audio_recording_input.dart';
import 'package:namer_app/widgets/event_input.dart';
import 'package:namer_app/widgets/example_tip.dart';
import 'package:namer_app/widgets/processing_indicator.dart';

class AIEventBody extends StatelessWidget {
  final AddAIEventController controller;
  final VoidCallback handlePaste;
  final Function(String wavFilePath) onRecordingComplete;

  AIEventBody({
    super.key, 
    required this.controller,
    required this.handlePaste,
    required this.onRecordingComplete
  });

  Widget _buildMainArea() {
    if (controller.isProcessing) {
      return ProcessingIndicatorWidget(
        processingType: controller.processingType,
      );
    }

    return EventInputWidget(
      onPaste: handlePaste,
      audioRecorder: AudioRecordingInput(
          onRecordingComplete: onRecordingComplete,
          onRecordingStart: () => controller.setRecording(true),
          onRecordingStop: () => controller.setRecording(false),
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.auto_awesome,
          size: 64,
          color: Theme.of(context).primaryColor,
        ),
        SizedBox(height: 12),
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
        SizedBox(height: 16),
        _buildMainArea(),
        SizedBox(height: 16),
        if (!controller.isProcessing && !controller.isRecording)
          ExampleTipWidget(),
      ],
    );
  }
}