import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:namer_app/main.dart';

GoogleSignIn googleSignInInstance = GoogleSignIn(
  params: GoogleSignInParams(
    redirectPort: 3000,
    clientId: envVars['google_client_id'],
    clientSecret: envVars['google_client_secret'] 
  ),
);