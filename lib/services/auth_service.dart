import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _client = Supabase.instance.client;

  // ── SIGN UP ───────────────────────────────────────────────────────────────
  Future<String?> signUp({
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String lastName,
  }) async {
    try {
      // 1. Check if username already exists
      final existing = await _client
          .from('profiles')
          .select('username')
          .eq('username', username.trim().toLowerCase())
          .maybeSingle();

      if (existing != null) {
        return 'Username already taken. Please choose another.';
      }

      // 2. Create auth user
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        return 'Sign up failed. Please try again.';
      }

      // 3. Save profile (including email for username login lookup)
      await _client.from('profiles').insert({
        'id': response.user!.id,
        'username': username.trim().toLowerCase(),
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'email': email.trim(),
      });

      return null; // null = success
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred: ${e.toString()}';
    }
  }

  // ── SIGN IN (email or username) ───────────────────────────────────────────
  Future<String?> signIn(String emailOrUsername, String password) async {
    try {
      String email = emailOrUsername.trim();

      // If input doesn't contain @, treat it as a username
      if (!email.contains('@')) {
        final profile = await _client
            .from('profiles')
            .select('email')
            .eq('username', email.toLowerCase())
            .maybeSingle();

        if (profile == null) {
          return 'No account found with that username.';
        }

        email = profile['email'] as String;
      }

      await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return null; // null = success
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  // ── SIGN OUT ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ── GET PROFILE ───────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    return await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
  }

  // ── RESET PASSWORD ────────────────────────────────────────────────────────
  Future<String?> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  // ── CURRENT USER ──────────────────────────────────────────────────────────
  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;
}