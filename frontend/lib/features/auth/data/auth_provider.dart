import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';

/// Provider for AuthService singleton
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Auth state enum
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  confirmSignUp,
  signUpComplete, // Added for showing success message
  error,
}

/// Auth state class
class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  final String? email; // Used during sign up flow
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.email,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? email,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      email: email ?? this.email,
      errorMessage: errorMessage,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
}

/// Auth notifier that handles authentication state
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _checkAuthStatus();
  }

  /// Check initial auth status
  Future<void> _checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);
    
    try {
      final isSignedIn = await _authService.isSignedIn();
      
      if (isSignedIn) {
        final user = await _authService.getCurrentUser();
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  /// Sign up a new user
  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, email: email);
    
    try {
      final result = await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (result.isSignUpComplete) {
        // Auto sign in if no confirmation required
        await signIn(email: email, password: password);
      } else {
        // Need email confirmation
        state = state.copyWith(
          status: AuthStatus.confirmSignUp,
          email: email,
        );
      }
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _mapAuthError(e),
      );
    }
  }

  /// Confirm sign up with verification code
  Future<bool> confirmSignUp({
    required String confirmationCode,
  }) async {
    if (state.email == null) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Email not found. Please sign up again.',
      );
      return false;
    }

    state = state.copyWith(status: AuthStatus.loading);
    
    try {
      final result = await _authService.confirmSignUp(
        email: state.email!,
        confirmationCode: confirmationCode,
      );

      if (result.isSignUpComplete) {
        state = state.copyWith(status: AuthStatus.signUpComplete);
        return true;
      } else {
        state = state.copyWith(
          status: AuthStatus.confirmSignUp,
          errorMessage: 'Confirmation not complete. Please try again.',
        );
        return false;
      }
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.confirmSignUp,
        errorMessage: _mapAuthError(e),
      );
      return false;
    }
  }

  /// Resend confirmation code
  Future<void> resendConfirmationCode() async {
    if (state.email == null) return;

    try {
      await _authService.resendSignUpCode(email: state.email!);
    } on AuthException catch (e) {
      state = state.copyWith(errorMessage: _mapAuthError(e));
    }
  }

  /// Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, email: email);
    
    try {
      final result = await _authService.signIn(
        email: email,
        password: password,
      );

      if (result.isSignedIn) {
        final user = await _authService.getCurrentUser();
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
      } else if (result.nextStep.signInStep == AuthSignInStep.confirmSignUp) {
        // User hasn't confirmed email yet
        state = state.copyWith(
          status: AuthStatus.confirmSignUp,
          email: email,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Sign in not complete. Please try again.',
        );
      }
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _mapAuthError(e),
      );
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading);
    
    try {
      await _authService.signOut();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        errorMessage: _mapAuthError(e),
      );
    }
  }

  /// Get ID token for API calls
  Future<String?> getIdToken() async {
    return _authService.getIdToken();
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Clear signup complete status (after showing success message)
  void clearSignUpComplete() {
    if (state.status == AuthStatus.signUpComplete) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  /// Map auth exceptions to user-friendly messages
  String _mapAuthError(AuthException e) {
    final message = e.message.toLowerCase();
    
    if (message.contains('user not found') || message.contains('usernotfound')) {
      return 'No account found with this email.';
    } else if (message.contains('incorrect') || message.contains('password')) {
      return 'Incorrect email or password.';
    } else if (message.contains('user already exists') || message.contains('usernameexists')) {
      return 'An account with this email already exists.';
    } else if (message.contains('invalid code') || message.contains('codemismatch')) {
      return 'Invalid verification code.';
    } else if (message.contains('expired')) {
      return 'Code has expired. Please request a new one.';
    } else if (message.contains('too many requests') || message.contains('limitexceeded')) {
      return 'Too many attempts. Please try again later.';
    } else if (message.contains('network') || message.contains('connection')) {
      return 'Network error. Please check your connection.';
    } else if (message.contains('not confirmed')) {
      return 'Please verify your email first.';
    }
    
    return e.message;
  }
}

/// Main auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

/// Convenience provider for checking if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// Provider for getting the current user
final currentUserProvider = Provider<AuthUser?>((ref) {
  return ref.watch(authProvider).user;
});
