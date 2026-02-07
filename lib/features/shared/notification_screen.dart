import 'package:cemetry/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) return [];
  
  final response = await supabase
      .from('notifications')
      .select()
      .eq('user_id', user.id)
      .order('created_at', ascending: false);
      
  return List<Map<String, dynamic>>.from(response);
});

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No notifications yet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final note = notifications[index];
              final isRead = note['is_read'] as bool? ?? false;
              
              return Card(
                elevation: isRead ? 0 : 2,
                margin: const EdgeInsets.only(bottom: 12),
                color: isRead ? Colors.grey[50] : Colors.white,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isRead ? Colors.grey[200] : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.notifications,
                      color: isRead ? Colors.grey : Theme.of(context).primaryColor,
                    ),
                  ),
                  title: Text(
                    note['title'] ?? 'Notification',
                    style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
                  ),
                  subtitle: Text(note['message'] ?? ''),
                  trailing: Text(
                    _formatTime(note['created_at']),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    final dt = DateTime.parse(timestamp);
    // Simple mock formatting
    return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
