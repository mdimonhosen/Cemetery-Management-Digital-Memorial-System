import 'package:cemetry/features/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Use a StateProvider for refresh trigger if needed, or just invalidate
final userProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) throw Exception('User not logged in');
  
  final data = await Supabase.instance.client
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .maybeSingle();
      
  if (data == null) {
    return {
      'id': user.id,
      'name': user.email?.split('@').first ?? 'User',
      'email': user.email,
      'mobile': null,
      'address': null,
      'count': 0,
    };
  }
      
  data['email'] = user.email; 
  return data;
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          profileAsync.when(
            data: (profile) => IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditProfileDialog(context, ref, profile),
            ),
            loading: () => const SizedBox(),
            error: (e, s) => const SizedBox(),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          final count = profile['count'] as int? ?? 0;
          final role = count == 1 ? 'Administrator' : 'User';
          
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                   Center(
                     child: CircleAvatar(
                       radius: 50,
                       backgroundColor: theme.colorScheme.primaryContainer,
                       child: Text(
                         (profile['name'] as String? ?? 'U')[0].toUpperCase(),
                         style: theme.textTheme.displayMedium?.copyWith(
                           color: theme.colorScheme.onPrimaryContainer,
                         ),
                       ),
                     ),
                   ),
                   const SizedBox(height: 16),
                   Text(
                     profile['name'] ?? 'No Name',
                     textAlign: TextAlign.center,
                     style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                   ),
                   Text(
                     role,
                     textAlign: TextAlign.center,
                     style: theme.textTheme.labelLarge?.copyWith(
                       color: theme.colorScheme.secondary,
                     ),
                   ),
                   const SizedBox(height: 32),
                   _buildInfoTile(context, Icons.email_outlined, 'Email', profile['email'] ?? 'Not set'),
                   _buildInfoTile(context, Icons.phone_android_outlined, 'Mobile', profile['mobile'] ?? 'Not set'),
                   _buildInfoTile(context, Icons.location_on_outlined, 'Address', profile['address'] ?? 'Not set'),
                   
                   const SizedBox(height: 32),
                   const Text('Security', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   Card(
                     child: Column(
                       children: [
                         ListTile(
                           leading: const Icon(Icons.lock_reset),
                           title: const Text('Change Password'),
                           trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                           onTap: () => _showChangePasswordDialog(context, ref),
                         ),
                         const Divider(height: 1),
                         ListTile(
                           leading: const Icon(Icons.mail_lock),
                           title: const Text('Change Email'),
                           trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                           onTap: () => _showChangeEmailDialog(context, ref),
                         ),
                       ],
                     ),
                   ),

                   const SizedBox(height: 48),
                   FilledButton.icon(
                     onPressed: () async {
                       await ref.read(authServiceProvider).signOut();
                     },
                     icon: const Icon(Icons.logout),
                     label: const Text('Sign Out'),
                     style: FilledButton.styleFrom(
                       backgroundColor: theme.colorScheme.error,
                       foregroundColor: theme.colorScheme.onError,
                     ),
                   )
                ],
              ),
            ),
          );
        },
        error: (err, stack) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, IconData icon, String label, String value) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(label, style: Theme.of(context).textTheme.bodySmall),
        subtitle: Text(
          value, 
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> profile) {
    final nameCtrl = TextEditingController(text: profile['name']);
    final mobileCtrl = TextEditingController(text: profile['mobile']);
    final addrCtrl = TextEditingController(text: profile['address']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
             TextField(controller: mobileCtrl, decoration: const InputDecoration(labelText: 'Mobile')),
            const SizedBox(height: 12),
             TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Address')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              try {
                await ref.read(authServiceProvider).updateProfile(
                  name: nameCtrl.text,
                  mobile: mobileCtrl.text,
                  address: addrCtrl.text,
                );
                ref.invalidate(userProfileProvider);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            }, 
            child: const Text('Save')
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: oldPassCtrl, decoration: const InputDecoration(labelText: 'Current Password'), obscureText: true),
            const SizedBox(height: 12),
            TextField(controller: newPassCtrl, decoration: const InputDecoration(labelText: 'New Password'), obscureText: true),
            const SizedBox(height: 12),
            TextField(controller: confirmPassCtrl, decoration: const InputDecoration(labelText: 'Confirm New Password'), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (newPassCtrl.text != confirmPassCtrl.text) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New passwords do not match')));
                 return;
              }
              try {
                await ref.read(authServiceProvider).changePassword(
                  currentPassword: oldPassCtrl.text,
                  newPassword: newPassCtrl.text,
                );
                if (context.mounted) {
                   Navigator.pop(context);
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully')));
                }
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            }, 
            child: const Text('Update')
          ),
        ],
      ),
    );
  }

   void _showChangeEmailDialog(BuildContext context, WidgetRef ref) {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'New Email'), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Current Password'), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              try {
                await ref.read(authServiceProvider).changeEmail(
                  newEmail: emailCtrl.text,
                  currentPassword: passCtrl.text,
                );
                if (context.mounted) {
                   Navigator.pop(context);
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Confirmation link sent to new email.')));
                }
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            }, 
            child: const Text('Update')
          ),
        ],
      ),
    );
  }

}
