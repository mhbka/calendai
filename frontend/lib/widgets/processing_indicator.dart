import 'package:flutter/material.dart';

class ProcessingIndicatorWidget extends StatelessWidget {
  final String processingType;
  final double height;

  const ProcessingIndicatorWidget({
    Key? key,
    required this.processingType,
    this.height = 300,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).primaryColor, width: 2),
        borderRadius: BorderRadius.circular(12),
        color: Colors.blue[50],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              processingType == 'audio' 
                  ? 'Processing audio...' 
                  : 'Processing text...',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}