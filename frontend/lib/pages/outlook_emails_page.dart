import 'package:flutter/material.dart';
import 'package:namer_app/pages/base_page.dart';

class OutlookEmailsPage extends StatefulWidget {
  @override
  _OutlookEmailsPageState createState() => _OutlookEmailsPageState();
}

class _OutlookEmailsPageState extends State<OutlookEmailsPage> {
  @override
  void initState() {
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: "Generate events from an Outlook email", 
      body: SizedBox(height: 48)
    );
  }
}