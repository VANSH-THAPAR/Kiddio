
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/chat_provider.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(userConversationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return const Center(child: Text("No messages yet."));
          }
          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(conversation.otherUser.profileImage ?? ''),
                ),
                title: Text(conversation.otherUser.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  conversation.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  timeago.format(conversation.lastMessageTime, locale: 'en_short'),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () {
                  context.push('/chat/${conversation.otherUser.uid}', extra: conversation.otherUser);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
