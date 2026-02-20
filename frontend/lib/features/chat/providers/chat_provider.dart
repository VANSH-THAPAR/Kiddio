
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_controller.dart';
import '../models/message_model.dart';
import '../../auth/models/user_model.dart';

final chatProvider = Provider((ref) => ChatController(ref));

class ChatController {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ChatController(this._ref);

  Future<void> sendMessage(String receiverId, String content) async {
    final user = _ref.read(authControllerProvider).user;
    if (user == null) return;

    final message = MessageModel(
      id: '',
      senderId: user.uid,
      receiverId: receiverId,
      content: content,
      timestamp: DateTime.now(),
    );

    // Add to 'chats' collection -> 'conversationId' -> 'messages'
    // To keep it simple, we can use a composite ID: userId1_userId2 (sorted)
    final conversationId = _getConversationId(user.uid, receiverId);

    await _firestore
        .collection('chats')
        .doc(conversationId)
        .collection('messages')
        .add(message.toMap());
        
    // Update last message in the conversation doc for the list view
    await _firestore.collection('chats').doc(conversationId).set({
      'users': [user.uid, receiverId],
      'lastMessage': content,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'readBy': [user.uid], // Mark as read by sender
    }, SetOptions(merge: true));
  }
  
  String _getConversationId(String id1, String id2) {
    return id1.compareTo(id2) < 0 ? '${id1}_$id2' : '${id2}_$id1';
  }
}

final chatMessagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, receiverId) {
  final user = ref.watch(authControllerProvider).user;
  if (user == null) return const Stream.empty();
  
  // We calculate conversationId independently to avoid exposing private methods
  final conversationId = (user.uid.compareTo(receiverId) < 0) 
      ? '${user.uid}_$receiverId' 
      : '${receiverId}_${user.uid}';

  return FirebaseFirestore.instance
      .collection('chats')
      .doc(conversationId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
        .toList();
  });
});

final userConversationsProvider = StreamProvider<List<ConversationModel>>((ref) {
  final user = ref.watch(authControllerProvider).user;
  if (user == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('chats')
      .where('users', arrayContains: user.uid)
      // .orderBy('lastMessageTime', descending: true) // Removed to avoid index requirement error
      .snapshots()
      .asyncMap((snapshot) async {
        List<ConversationModel> conversations = [];
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final List<dynamic> users = data['users'];
          final otherUserId = users.firstWhere((id) => id != user.uid);
          
          // Fetch other user details
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(otherUserId).get();
          if (!userDoc.exists) continue;
          
          final otherUser = UserModel.fromMap(userDoc.data()!, otherUserId);
          
          conversations.add(ConversationModel(
            conversationId: doc.id,
            otherUser: otherUser,
            lastMessage: data['lastMessage'] ?? '',
            lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
          ));
        }
        conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        return conversations;
      });
});

class ConversationModel {
  final String conversationId;
  final UserModel otherUser;
  final String lastMessage;
  final DateTime lastMessageTime;

  ConversationModel({
    required this.conversationId,
    required this.otherUser,
    required this.lastMessage,
    required this.lastMessageTime,
  });
}
