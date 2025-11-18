import 'package:calendai/widgets/audio_recorder.dart';
import 'package:flutter/material.dart';
import 'package:calendai/widgets/audio_recording_input.dart';

class EventInputWidget extends StatelessWidget {
  final AudioRecordingInput audioRecorder;
  final AudioProcessorWidget audioRecorderNew;
  final VoidCallback onPaste;
  final double height;

  const EventInputWidget({
    super.key,
    required this.audioRecorder,
    required this.audioRecorderNew,
    required this.onPaste,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 2),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: Column(
        children: [
          Expanded(
            child: InkWell(
              onTap: onPaste,
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.content_paste,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Paste your text or image here',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Normal and recurring events will be generated for you',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            height: 1,
            color: Colors.grey[300],
          ),
          Card(
            shadowColor: Colors.transparent,
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [audioRecorder, audioRecorderNew],
              ),
            ),
          ),
        ],
      ),
    );
  }
}