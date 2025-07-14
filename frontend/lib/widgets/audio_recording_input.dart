import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

enum RecordingState { idle, recording, processing }

class AudioRecordingInput extends StatefulWidget {
  final Function(Uint8List audioData) onRecordingComplete;
  final VoidCallback? onRecordingStart;
  final VoidCallback? onRecordingStop;

  const AudioRecordingInput({
    super.key,
    required this.onRecordingComplete,
    this.onRecordingStart,
    this.onRecordingStop,
  });

  @override
  _AudioRecordingInputState createState() => _AudioRecordingInputState();
}

class _AudioRecordingInputState extends State<AudioRecordingInput> with TickerProviderStateMixin {
  RecordingState _state = RecordingState.idle;
  Timer? _recordingTimer;
  int _recordingDuration = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final AudioRecorder _recorder = AudioRecorder();
  late Stream<Uint8List> _audioRecording;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _pulseController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_state == RecordingState.idle) {
      await _startRecording();
    } else if (_state == RecordingState.recording) {
      await _stopRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      setState(() {
        _state = RecordingState.recording;
        _recordingDuration = 0;
      });

      widget.onRecordingStart?.call();

      if (await _recorder.hasPermission()) {
        _pulseController.repeat(reverse: true);
      
        _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
          setState(() {
            _recordingDuration++;
          });
        });

        _audioRecording = await _recorder.startStream(const RecordConfig(encoder: AudioEncoder.pcm16bits));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start recording: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      setState(() {
        _state = RecordingState.processing;
      });

      _recordingTimer?.cancel();
      _pulseController.stop();
      _recorder.stop();
      widget.onRecordingStop?.call();

      print("lists: ${await _audioRecording.length}");
      widget.onRecordingComplete(await _audioRecording.first);

      setState(() {
        _state = RecordingState.idle;
        _recordingDuration = 0;
      });
    } catch (e) {
      setState(() {
        _state = RecordingState.idle;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to stop recording: $e')),
      );
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
Widget build(BuildContext context) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _state == RecordingState.recording ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getButtonColor(),
                    boxShadow: _state == RecordingState.recording
                        ? [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ]
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(40),
                      onTap: _state == RecordingState.processing ? null : _toggleRecording,
                      child: Center(
                        child: _getButtonIcon(),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getStatusText(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: _getTextColor(),
                    ),
              ),
              if (_state == RecordingState.recording) ...[
                SizedBox(height: 4),
                Text(
                  _formatDuration(_recordingDuration),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                ),
              ],
            ],
          ),
        ],
      ),
    ],
  );
}

  Color _getButtonColor() { 
    switch (_state) {
      case RecordingState.idle:
        return Theme.of(context).primaryColor;
      case RecordingState.recording:
        return Colors.red;
      case RecordingState.processing:
        return Colors.grey;
    }
  }

  Widget _getButtonIcon() {
    switch (_state) {
      case RecordingState.idle:
        return Icon(Icons.mic, color: Colors.white, size: 32);
      case RecordingState.recording:
        return Icon(Icons.stop, color: Colors.white, size: 32);
      case RecordingState.processing:
        return SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        );
    }
  }

  String _getStatusText() {
    switch (_state) {
      case RecordingState.idle:
        return 'Tap to start recording';
      case RecordingState.recording:
        return 'Recording... Tap to stop';
      case RecordingState.processing:
        return 'Processing audio...';
    }
  }

  Color _getTextColor() {
    switch (_state) {
      case RecordingState.idle:
        return Colors.grey[600]!;
      case RecordingState.recording:
        return Colors.red;
      case RecordingState.processing:
        return Colors.orange;
    }
  }
}