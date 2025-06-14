import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final supabase = Supabase.instance.client;
  late GoogleSignIn _googleSignIn;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _googleSignIn = GoogleSignIn(
      params: GoogleSignInParams(
        redirectPort: 3000,
      ),
    );
  }
  

  Future<void> _nativeGoogleSignIn() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await _phoneGoogleSignIn();
    }
    else {
      await _webGoogleSignIn();
    }

    /*
    final credentials = await _googleSignIn.signIn();
    if (credentials != null) {
      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: credentials.idToken!, // TODO: check if this is actually not null
        accessToken: credentials.accessToken
      );
    }
    else {
      // TODO: proper error handling or something
      print('gg nerd');
    }
    */
  }

  Future<void> _phoneGoogleSignIn() async {
    final googleUser = await _googleSignIn.signIn();
    final accessToken = googleUser!.accessToken;
    final idToken = googleUser.idToken;

    if (idToken == null) {
      throw 'No idToken returned';
    }
    else {
      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google, 
        idToken: idToken,
        accessToken: accessToken
      );
    }
  }

  Future<void> _webGoogleSignIn() async {
    await supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: true ? null : 'calendai://google-login-callback', // TODO: set up this deeplink?
      authScreenLaunchMode: LaunchMode.externalApplication, 
    );
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
                'Sign in to Google',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _nativeGoogleSignIn,
                icon: _isLoading 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.login), // TODO: replace with Google icon
                label: Text(
                  _isLoading ? 'Signing in...' : 'Sign in with Google',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
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
