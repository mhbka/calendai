import 'package:flutter/material.dart';
import 'package:namer_app/services/azure_token_api_service.dart';
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
                authScreenLaunchMode: LaunchMode.externalApplication,
                showSuccessSnackBar: false,
                scopes: {
                  OAuthProvider.azure: 'offline_access https://graph.microsoft.com/.default'
                },
                queryParams: {
                  OAuthProvider.azure: {
                    'prompt': 'consent'
                  }
                },
                onSuccess: (session) async {
                  try {
                    await AzureTokenApiService.sendAzureToken();
                    if (context.mounted) await Alerts.showConfirmationDialog(context, "Successful login", "You've successfully logged in.");
                  } catch (e) {
                    await Supabase.instance.client.auth.signOut();
                    if (context.mounted) await Alerts.showErrorDialog(context, "Failed to sign in", "Failed to sign in. Please try again later.");
                  }
                 },
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'An AI-integrated calendar',
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
