import 'package:chatapp/features/chat/presentation/widget/message_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatMessages extends StatelessWidget {
  const ChatMessages({super.key});

  @override
  Widget build(BuildContext context) {
    final authenticatedUser = FirebaseAuth.instance.currentUser!;
    return StreamBuilder(
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No messages yet'),
          );
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text('An error occurred'),
          );
        }
        return ListView.builder(
          reverse: true,
          padding:
              const EdgeInsets.only(top: 15, bottom: 15, left: 15, right: 15),
          itemBuilder: (context, index) {
            final chatData = snapshot.data!.docs[index].data();
            final nextChatMessage = snapshot.data!.docs.length > index + 1
                ? snapshot.data!.docs[index + 1].data()
                : null;

            final currentMessageUserId = chatData['userId'];
            final nextMessageUserId =
                nextChatMessage != null ? nextChatMessage['userId'] : null;

            // Check if this is the first message or from a different user
            final isFirstMessage = nextMessageUserId == null ||
                currentMessageUserId != nextMessageUserId;

            // Render different widgets based on whether it's the first message
            if (isFirstMessage) {
              return MessageBubble.first(
                userImage: chatData['image_url'] ?? '',
                username: chatData['username'] ?? 'Unknown User',
                message: chatData['text'] ?? '',
                isMe: authenticatedUser.uid == currentMessageUserId,
              );
            } else {
              return MessageBubble.next(
                message: chatData['text'] ?? '',
                isMe: authenticatedUser.uid == currentMessageUserId,
              );
            }
          },
          itemCount: snapshot.data!.docs.length,
        );
      },
      stream: FirebaseFirestore.instance
          .collection('chat')
          .orderBy('createdAt', descending: true)
          .snapshots(),
    );
  }
}
