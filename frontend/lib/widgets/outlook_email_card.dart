import 'package:flutter/material.dart';
import 'package:namer_app/models/outlook_email.dart';

class OutlookEmailCard extends StatelessWidget {
  final OutlookEmailMessage email;

  OutlookEmailCard({
    super.key,
    required this.email
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: _buildCardBody(context)
    );
  }
  
  Widget _buildCardBody(BuildContext context) {
    return SizedBox(
        height: 50,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Subject: ${email.subject}",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              "From: ${email.from.emailAddress.address} (${email.from.emailAddress.name})",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              "Sent: ${email.sentDateTime}",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              "Body: ${email.bodyPreview}",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
  }
}