import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

/// Service for handling authentication with AWS Cognito
class AuthService {
  /// Sign up a new user with email and password
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final result = await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: SignUpOptions(
          userAttributes: {
            AuthUserAttributeKey.email: email,
            if (displayName != null && displayName.isNotEmpty)
              AuthUserAttributeKey.name: displayName,
          },
        ),
      );
      return result;
    } on AuthException catch (e) {
      safePrint('Sign up error: ${e.message}');
      rethrow;
    }
  }

  /// Confirm sign up with verification code
  Future<SignUpResult> confirmSignUp({
    required String email,
    required String confirmationCode,
  }) async {
    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: email,
        confirmationCode: confirmationCode,
      );
      return result;
    } on AuthException catch (e) {
      safePrint('Confirm sign up error: ${e.message}');
      rethrow;
    }
  }

  /// Resend confirmation code
  Future<ResendSignUpCodeResult> resendSignUpCode({
    required String email,
  }) async {
    try {
      final result = await Amplify.Auth.resendSignUpCode(
        username: email,
      );
      return result;
    } on AuthException catch (e) {
      safePrint('Resend code error: ${e.message}');
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<SignInResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final result = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );
      return result;
    } on AuthException catch (e) {
      safePrint('Sign in error: ${e.message}');
      rethrow;
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut();
    } on AuthException catch (e) {
      safePrint('Sign out error: ${e.message}');
      rethrow;
    }
  }

  /// Check if user is signed in
  Future<bool> isSignedIn() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      return session.isSignedIn;
    } on AuthException catch (e) {
      safePrint('Auth session error: ${e.message}');
      return false;
    }
  }

  /// Get current authenticated user
  Future<AuthUser?> getCurrentUser() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      return user;
    } on AuthException catch (e) {
      safePrint('Get current user error: ${e.message}');
      return null;
    }
  }

  /// Get the current user's ID token for API calls
  Future<String?> getIdToken() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession(
        options: const FetchAuthSessionOptions(forceRefresh: false),
      );
      
      if (session is CognitoAuthSession) {
        return session.userPoolTokensResult.value.idToken.raw;
      }
      return null;
    } on AuthException catch (e) {
      safePrint('Get ID token error: ${e.message}');
      return null;
    }
  }

  /// Get user attributes (email, name, etc.)
  Future<List<AuthUserAttribute>> getUserAttributes() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      return attributes;
    } on AuthException catch (e) {
      safePrint('Get attributes error: ${e.message}');
      return [];
    }
  }

  /// Initiate forgot password flow
  Future<ResetPasswordResult> forgotPassword({
    required String email,
  }) async {
    try {
      final result = await Amplify.Auth.resetPassword(
        username: email,
      );
      return result;
    } on AuthException catch (e) {
      safePrint('Forgot password error: ${e.message}');
      rethrow;
    }
  }

  /// Confirm new password with reset code
  Future<ResetPasswordResult> confirmResetPassword({
    required String email,
    required String newPassword,
    required String confirmationCode,
  }) async {
    try {
      final result = await Amplify.Auth.confirmResetPassword(
        username: email,
        newPassword: newPassword,
        confirmationCode: confirmationCode,
      );
      return result;
    } on AuthException catch (e) {
      safePrint('Confirm reset password error: ${e.message}');
      rethrow;
    }
  }
}
