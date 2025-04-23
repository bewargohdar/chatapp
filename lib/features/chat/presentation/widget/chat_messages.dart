import 'package:chatapp/features/chat/presentation/bloc/bloc/chat_bloc.dart';
import 'package:chatapp/features/chat/presentation/bloc/bloc/chat_event.dart';
import 'package:chatapp/features/chat/presentation/bloc/bloc/chat_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chatapp/features/chat/domain/entity/message.dart';
import 'package:chatapp/features/auth/domain/entity/user.dart';

import 'package:chatapp/features/chat/presentation/widget/message_bubble.dart';

class ChatMessages extends StatefulWidget {
  final UserEntity? selectedUser;

  const ChatMessages({
    super.key,
    this.selectedUser,
  });

  @override
  State<ChatMessages> createState() => _ChatMessagesState();
}

class _ChatMessagesState extends State<ChatMessages> {
  List<MessageEntity> _currentMessages = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Initialize the chat by fetching messages with the selected user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<ChatBloc>()
          .add(FetchMessagesEvent(selectedUser: widget.selectedUser));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state is ChatLoadingState) {
          setState(() {
            _isLoading = true;
          });
        } else if (state is ChatErrorState) {
          setState(() {
            _isLoading = false;
            _errorMessage = state.message;
          });
        } else if (state is ChatMessagesFetchedState) {
          setState(() {
            _isLoading = false;
            _errorMessage = null;
            _currentMessages = state.messages;
          });
        }
      },
      builder: (context, state) {
        if (_isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (_errorMessage != null) {
          return Center(
            child: Text(_errorMessage!),
          );
        }

        if (_currentMessages.isEmpty) {
          return const Center(child: Text('No messages yet'));
        }

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
          itemCount: _currentMessages.length,
          itemBuilder: (context, index) {
            final message = _currentMessages[index];
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
      },
    );
  }
}
