import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../data/models.dart';

class AuthState extends ChangeNotifier {
  AuthState() {
    _init();
  }

  Session? session;
  Profile? profile;
  bool loading = true;

  User? get user => session?.user;

  Future<void> _init() async {
    session = supabase.auth.currentSession;
    if (session != null) {
      await _loadProfile();
    }
    loading = false;
    notifyListeners();

    supabase.auth.onAuthStateChange.listen((data) {
      session = data.session;
      if (session != null) {
        _loadProfile();
      } else {
        profile = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadProfile() async {
    final userId = session?.user.id;
    if (userId == null) return;
    final data = await supabase.from('profiles').select().eq('id', userId).maybeSingle();
    profile = data != null ? Profile.fromJson(data) : null;
    notifyListeners();
  }

  Future<String?> signIn({required String email, required String password}) async {
    try {
      await supabase.auth.signInWithPassword(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'role': role},
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  Future<void> refreshProfile() => _loadProfile();
}
