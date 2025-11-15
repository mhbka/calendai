import 'package:flutter/material.dart';
import 'package:namer_app/controllers/outlook_emails_controller.dart';
import 'package:namer_app/pages/base_page.dart';
import 'package:namer_app/utils/alerts.dart';
import 'package:namer_app/widgets/outlook_email_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OutlookEmailsPage extends StatefulWidget {
  @override
  _OutlookEmailsPageState createState() => _OutlookEmailsPageState();
}

class _OutlookEmailsPageState extends State<OutlookEmailsPage> {
  final OutlookEmailsController _controller = OutlookEmailsController.instance;

  @override
  void initState() {
    super.initState();
    _controller
      .loadEmails()
      .catchError((err) {
        if (mounted) Alerts.showErrorSnackBar(context, "Failed to load events: $err. Please try again later");
      });
  }
  
  @override
  Widget build(BuildContext context) {
    
    print("Provider token: ${Supabase.instance.client.auth.currentSession?.providerToken}");
    print("Provider refresh token: ${Supabase.instance.client.auth.currentSession?.providerRefreshToken}");
    
    return BasePage(
      title: "Generate events from an Outlook email", 
      body: _controller.isLoading ? _buildLoading() : _buildMainArea()
    );
  }

  Widget _buildMainArea() {
    if (_controller.emails.isEmpty) {
      return Center(
        child: Container(
          margin: EdgeInsets.all(32),
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "No emails were found in your Outlook.",
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              )
            ],
          ),
        ),
      );
    }
    else {
      return RefreshIndicator(
        onRefresh: () async {
          await _controller.loadEmails();
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: _controller.emails.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: OutlookEmailCard(
                email: _controller.emails[index]
              ),
            );
          },
        ),
      );
    }
  }

  Widget _buildLoading() {
    return Center(child: CircularProgressIndicator());
  }
}