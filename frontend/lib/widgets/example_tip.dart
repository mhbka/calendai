import 'package:flutter/material.dart';

class ExampleTipWidget extends StatelessWidget {
  final String exampleText;

  const ExampleTipWidget({
    super.key,
    this.exampleText = '"Meeting with Sarah tomorrow at 3 PM in Conference Room A to discuss the quarterly budget review"',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, 
                   color: Colors.blue[700], size: 20),
              SizedBox(width: 8),
              Text(
                'Example:',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            exampleText,
            style: TextStyle(
              color: Colors.blue[700],
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}