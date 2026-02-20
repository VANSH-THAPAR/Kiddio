
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_controller.dart';
import '../providers/chat_provider.dart';
import '../../auth/models/user_model.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final UserModel otherUser;

  const ChatScreen({super.key, required this.otherUser});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    ref.read(chatProvider).sendMessage(widget.otherUser.uid, content);
    _messageController.clear();
    // Scroll to bottom after sending
    // _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authControllerProvider).user;
    final messagesAsync = ref.watch(chatMessagesProvider(widget.otherUser.uid));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(widget.otherUser.profileImage ?? ''),
            ),
            const SizedBox(width: 8),
            Text(widget.otherUser.name, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(child: Text("Start a conversation!"));
                }
                return ListView.builder(
                  reverse: true, // Show latest messages at the bottom
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUser?.uid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20).copyWith(
                            bottomRight: isMe ? const Radius.circular(0) : null,
                            bottomLeft: !isMe ? const Radius.circular(0) : null,
                          ),
                        ),
                        child: Text(
                          message.content,
                          style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text("Error: $err")),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send, color: Colors.blue),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
