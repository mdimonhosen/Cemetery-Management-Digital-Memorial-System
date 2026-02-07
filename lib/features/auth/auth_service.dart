import 'package:cemetry/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authServiceProvider = Provider((ref) => AuthService());

final authStateProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});

class AuthService {
  Future<AuthResponse> signIn(String email, String password) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String mobile,
    required String address,
    required String role, 
    String? relation,
    required bool acceptedTerms,
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'mobile': mobile,
        'address': address,
        'role': role,
        'relation': relation,
        'accepted_terms': acceptedTerms,
      },
    );
    
    // Profile creation is now handled by the 'on_auth_user_created' database trigger.
    // We do NOT need to manually insert into 'profiles' table.
    // This avoids RLS issues and race conditions.

    // Sign out immediately to prevent auto-login
    await signOut();

    return response;
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  Future<void> updateProfile({
    required String name,
    required String mobile,
    required String address,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('No user logged in');
    await supabase.from('profiles').update({
      'name': name,
      'mobile': mobile,
      'address': address,
    }).eq('id', user.id);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null || user.email == null) throw Exception('No user logged in');

    // re-authenticate to verify old password
    final authResponse = await supabase.auth.signInWithPassword(
      email: user.email!,
      password: currentPassword,
    );
    
    if (authResponse.user == null) throw Exception('Incorrect current password');

    await supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> changeEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    final user = supabase.auth.currentUser;
     if (user == null || user.email == null) throw Exception('No user logged in');

    // re-authenticate to verify password
    final authResponse = await supabase.auth.signInWithPassword(
      email: user.email!,
      password: currentPassword,
    );

    if (authResponse.user == null) throw Exception('Incorrect password');

    await supabase.auth.updateUser(
      UserAttributes(email: newEmail),
    );
  }

  Future<int> getUserRole() async {
    final user = supabase.auth.currentUser;
    if (user == null) return 0;

    try {
      final data = await supabase
          .from('profiles')
          .select('role, count')
          .eq('id', user.id)
          .single();
      
      final count = data['count'] as int?;
      final role = data['role'] as String?;
      
      // Admin if count is 1 OR role is 'admin'
      if (count == 1 || role == 'admin') return 1;
      return 0;
    } catch (e) {
      // Default to 0 if error or no profile found
      return 0;
    }
  }

  Future<void> createAdmin({
    required String email,
    required String password,
    required String name,
    required String mobile,
    required String address,
  }) async {
    final tempClient = SupabaseClient(
      'https://zrdrxnymwvsxjtylhcun.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpyZHJ4bnltd3ZzeGp0eWxoY3VuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg4OTc0MDEsImV4cCI6MjA4NDQ3MzQwMX0.InsrWH-2hNcpej2Sl76pHIKqFtb7sfZZJm3vnPRHMb0',
      authOptions: const AuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
    );
    await tempClient.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'mobile': mobile,
        'address': address,
        'role': 'admin',
      },
    );
    // Dispose the temp client if possible/needed (SupabaseClient doesn't have dispose, it's just a light wrapper)
  }
}
