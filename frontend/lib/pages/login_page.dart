import 'package:flutter/material.dart';
import 'package:namer_app/utils/alerts.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              
              Text(
                'Welcome',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Sign in to Calendai',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),

              SupaSocialsAuth(
                socialProviders: [
                  OAuthProvider.azure,
                ],
                colored: true,
                authScreenLaunchMode: LaunchMode.inAppWebView,
                showSuccessSnackBar: false,
                scopes: {
                  OAuthProvider.azure: 'email Calendars.ReadWrite.Shared'
                },
                onSuccess: (session) => { 
                  Alerts.showConfirmationDialog(context, "Successful login", "You've successfully logged in. Provider: ${session.providerToken}")
                 },
                onError: (error) => {
                  Alerts.showErrorSnackBar(context, "Failed to log in: $error.")
                },
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'By signing in, you agree to our Terms of Service and Privacy Policy',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
