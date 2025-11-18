import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';

class AudioProcessorWidget extends StatefulWidget {
  final Function(String mp3FilePath) onRecordingComplete;

  const AudioProcessorWidget({
    super.key,
    required this.onRecordingComplete,
  });

  @override
  _AudioProcessorWidgetState createState() => _AudioProcessorWidgetState();
}

class _AudioProcessorWidgetState extends State<AudioProcessorWidget> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  String? _mp3FilePath;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final tempDir = await getTemporaryDirectory();
    _mp3FilePath = '${tempDir.path}/recorded.mp3';

    await _recorder.startRecorder(
      toFile: _mp3FilePath,
      codec: Codec.mp3, // Directly record to MP3
      sampleRate: 44100,
      numChannels: 2,
    );

    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() => _isRecording = false);

    if (_mp3FilePath != null) {
      widget.onRecordingComplete(_mp3FilePath!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _isRecording ? _stopRecording : _startRecording,
          child: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
        ),
      ],
    );
  }
}
