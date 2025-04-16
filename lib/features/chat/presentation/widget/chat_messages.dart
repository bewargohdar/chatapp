import 'package:chatapp/features/chat/presentation/bloc/bloc/chat_bloc.dart';
import 'package:chatapp/features/chat/presentation/bloc/bloc/chat_event.dart';
import 'package:chatapp/features/chat/presentation/bloc/bloc/chat_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chatapp/features/chat/domain/entity/message.dart';
import 'package:chatapp/features/auth/domain/entity/user.dart';

import 'package:chatapp/features/chat/presentation/widget/message_bubble.dart';

class ChatMessages extends StatelessWidget {
  final UserEntity? selectedUser;

  const ChatMessages({
    super.key,
    this.selectedUser,
  });

  @override
  Widget build(BuildContext context) {
    // Initialize the chat by fetching messages with the selected user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<ChatBloc>()
          .add(FetchMessagesEvent(selectedUser: selectedUser));
    });

    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        if (state is ChatLoadingState) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state is ChatErrorState) {
          return Center(
            child: Text(state.message),
          );
        }

        if (state is ChatMessagesFetchedState) {
          final List<MessageEntity> messages = state.messages;
          if (messages.isEmpty) {
            return const Center(child: Text('No messages yet'));
          }
          return ListView.builder(
            reverse: true,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final isMe =
                  message.userId == FirebaseAuth.instance.currentUser?.uid;
              return MessageBubble.first(
                userImage: message.imageUrl,
                username: message.username,
                message: message.text,
                isMe: isMe,
                voiceUrl: message.voiceUrl,
                messageType: message.messageType,
              );
            },
          );
        }

        return const Center(
          child: Text('No messages available'),
        );
      },
    );
  }
}
