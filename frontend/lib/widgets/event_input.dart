import 'package:flutter/material.dart';
import 'package:namer_app/widgets/audio_recording_input.dart';

class EventInputWidget extends StatelessWidget {
  final AudioRecordingInput audioRecorder;
  final VoidCallback onPaste;
  final VoidCallback onStartRecording;
  final double height;

  const EventInputWidget({
    Key? key,
    required this.audioRecorder,
    required this.onPaste,
    required this.onStartRecording,
    this.height = 300,
  }) : super(key: key);

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
                      'Paste your text here',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Describe your event and AI will create it for you',
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
                children: [audioRecorder],
              ),
            ),
          ),
        ],
      ),
    );
  }
}