import 'package:flutter/material.dart';
import 'package:namer_app/models/outlook_email.dart';
import 'package:namer_app/services/outlook_email_api_service.dart';

class OutlookEmailsController extends ChangeNotifier {
  // singleton stuff

  OutlookEmailsController._internal() {
  }

  static final OutlookEmailsController _instance = OutlookEmailsController._internal();

  factory OutlookEmailsController() {
    return _instance;
  }

  static OutlookEmailsController get instance => _instance;

  // members

  List<OutlookEmailMessage> _emails = [];
  bool _isLoading = false;

  List<OutlookEmailMessage> get emails => _emails;
  bool get isLoading => _isLoading;

  Future<void> loadEmails() async {
    try { 
      _setLoading(true);
      _emails = await OutlookEmailApiService.fetchUserEmails();
    } 
    catch (e) {
      rethrow;
    } 
    finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}