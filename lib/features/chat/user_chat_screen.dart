import 'package:cemetry/features/chat/chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserChatRequestScreen extends ConsumerWidget {
  const UserChatRequestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatRequestAsync = ref.watch(userChatRequestProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Chat')),
      body: chatRequestAsync.when(
        data: (request) {
          if (request == null) {
            return _buildInitialState(context, ref);
          }

          final status = request['status'];
          if (status == 'pending') {
            return _buildPendingState(context, ref);
          } else if (status == 'rejected') {
            return _buildRejectedState(context, ref);
          } else {
            return ChatRoomScreen(requestId: request['id']);
          }
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildInitialState(BuildContext context, WidgetRef ref) {
    final adminsAsync = ref.watch(allAdminsProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Support Chat',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select an administrator to start a conversation.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: adminsAsync.when(
              data: (admins) {
                if (admins.isEmpty) {
                  return const Center(
                    child: Text('No administrators available at the moment.'),
                  );
                }
                return ListView.builder(
                  itemCount: admins.length,
                  itemBuilder: (context, index) {
                    final admin = admins[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            (admin['name'] as String? ?? 'A')[0].toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          admin['name'] ?? 'Administrator',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(admin['email'] ?? 'Support Team'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _sendRequest(context, ref, admin['id']),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendRequest(BuildContext context, WidgetRef ref, String adminId) async {
    try {
      await ref.read(chatControllerProvider).requestChat(adminId: adminId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat request sent! Waiting for admin.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildPendingState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          const Text('Request Pending', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('The administrator will review your request soon.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () async {
               final req = ref.read(userChatRequestProvider).value;
               if (req != null) {
                 await ref.read(chatControllerProvider).rejectChat(req['id']);
               }
            }, 
            child: const Text('Cancel Request', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.block, size: 64, color: Colors.red),
          const SizedBox(height: 24),
          const Text('Request Rejected', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Your chat request was not approved this time.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => ref.read(chatControllerProvider).requestChat(),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String requestId;
  const ChatRoomScreen({super.key, required this.requestId});

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    ref.read(chatControllerProvider).sendMessage(widget.requestId, _messageController.text.trim());
    _messageController.clear();
  }
  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.requestId));

    return Column(
      children: [
        Expanded(
          child: messagesAsync.when(
            data: (messages) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                 if (_scrollController.hasClients) {
                   _scrollController.animateTo(
                     _scrollController.position.maxScrollExtent,
                     duration: const Duration(milliseconds: 300),
                     curve: Curves.easeOut,
                   );
                 }
              });
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg['sender_id'] == ref.read(chatControllerProvider).currentUserId; 
                  return _MessageBubble(text: msg['text'], isMe: isMe);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send, color: Colors.blue)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;

  const _MessageBubble({required this.text, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
            bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(0),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(color: isMe ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}
