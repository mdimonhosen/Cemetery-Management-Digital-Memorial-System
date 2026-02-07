import 'package:cemetry/features/chat/chat_controller.dart';
import 'package:cemetry/main.dart'; // To get supabase for sender id check
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminChatListScreen extends ConsumerWidget {
  const AdminChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingChatRequestsProvider);
    final approvedAsync = ref.watch(approvedChatRequestsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chat Management'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Requests'),
              Tab(text: 'Active Chats'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPendingList(context, ref, pendingAsync),
            _buildActiveList(context, ref, approvedAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingList(BuildContext context, WidgetRef ref, AsyncValue<List<Map<String, dynamic>>> async) {
    return async.when(
      data: (requests) {
        if (requests.isEmpty) return const Center(child: Text('No pending chat requests.'));
        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            final profileAsync = ref.watch(profileByIdProvider(req['user_id']));

            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: profileAsync.when(
                data: (p) => Text(p?['name'] ?? 'User ${req['user_id'].toString().substring(0, 4)}'),
                loading: () => const Text('Loading...'),
                error: (e, s) => const Text('Unknown User'),
              ),
              subtitle: const Text('Requested a chat session'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red), 
                    onPressed: () async {
                      try {
                        await ref.read(chatControllerProvider).rejectChat(req['id']);
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat rejected')));
                      } catch (e) {
                         if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green), 
                    onPressed: () async {
                      try {
                        await ref.read(chatControllerProvider).approveChat(req['id']);
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat approved!')));
                      } catch (e) {
                         if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildActiveList(BuildContext context, WidgetRef ref, AsyncValue<List<Map<String, dynamic>>> async) {
    return async.when(
      data: (chats) {
        if (chats.isEmpty) return const Center(child: Text('No active chats.'));
        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            final profileAsync = ref.watch(profileByIdProvider(chat['user_id']));

            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: profileAsync.when(
                data: (p) => Text(p?['name'] ?? 'User ${chat['user_id'].toString().substring(0, 4)}'),
                loading: () => const Text('Loading...'),
                error: (e, s) => const Text('Unknown User'),
              ),
              subtitle: const Text('Active chat session'),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                      title: profileAsync.when(
                        data: (p) => Text('Chat: ${p?['name'] ?? 'User'}'),
                        loading: () => const Text('Messaging'),
                        error: (e, s) => const Text('Messaging'),
                      ),
                    ),
                    body: Column(
                      children: [
                        _AdminChatRoomWrapper(requestId: chat['id']),
                        _AdminMessageInput(requestId: chat['id']),
                      ],
                    ),
                  ),
                ));
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

class _AdminChatRoomWrapper extends ConsumerStatefulWidget {
  final String requestId;
  const _AdminChatRoomWrapper({required this.requestId});

  @override
  ConsumerState<_AdminChatRoomWrapper> createState() => _AdminChatRoomWrapperState();
}

class _AdminChatRoomWrapperState extends ConsumerState<_AdminChatRoomWrapper> {
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.requestId));
    final currentUserId = supabase.auth.currentUser?.id;

    return Expanded(
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
              final isMe = msg['sender_id'] == currentUserId;
              return _SharedMessageBubble(text: msg['text'], isMe: isMe);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SharedMessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;

  const _SharedMessageBubble({required this.text, required this.isMe});

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

class _AdminMessageInput extends ConsumerStatefulWidget {
  final String requestId;
  const _AdminMessageInput({required this.requestId});

  @override
  _AdminMessageInputState createState() => _AdminMessageInputState();
}

class _AdminMessageInputState extends ConsumerState<_AdminMessageInput> {
  final _controller = TextEditingController();

  void _send() {
    if (_controller.text.trim().isEmpty) return;
    ref.read(chatControllerProvider).sendMessage(widget.requestId, _controller.text.trim());
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black12))),
      child: Row(
        children: [
          Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: 'Type message...', border: InputBorder.none))),
          IconButton(onPressed: _send, icon: const Icon(Icons.send, color: Colors.blue)),
        ],
      ),
    );
  }
}
