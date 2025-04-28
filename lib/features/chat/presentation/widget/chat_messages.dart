import 'package:chatapp/features/chat/presentation/bloc/bloc/chat_bloc.dart';
import 'package:chatapp/features/chat/presentation/bloc/bloc/chat_event.dart';
import 'package:chatapp/features/chat/presentation/bloc/bloc/chat_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chatapp/features/chat/domain/entity/message.dart';
import 'package:chatapp/features/auth/domain/entity/user.dart';

import 'package:chatapp/features/chat/presentation/widget/message_bubble.dart';
import 'package:chatapp/features/chat/presentation/widget/typing_indicator.dart';

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
  List<MessageEntity> _messages = [];
  bool _isPartnerTyping = false;

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
        if (state is ChatMessagesFetchedState) {
          setState(() {
            _messages = state.messages;
            _isPartnerTyping = state.isTyping;
          });
        }
      },
      builder: (context, state) {
        // Show loading indicator only when initially loading and messages are empty
        if (state is ChatLoadingState && _messages.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state is ChatErrorState) {
          return Center(
            child: Text(state.message),
          );
        }

        // Use cached messages if available, otherwise show empty state
        if (_messages.isNotEmpty || _isPartnerTyping) {
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  padding: EdgeInsets.only(
                      top: 15,
                      left: 15,
                      right: 15,
                      bottom: _isPartnerTyping ? 0 : 15),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isMe = message.userId ==
                        FirebaseAuth.instance.currentUser?.uid;
                    return MessageBubble.first(
                      userImage: message.imageUrl,
                      username: message.username,
                      message: message.text,
                      isMe: isMe,
                      voiceUrl: message.voiceUrl,
                      messageType: message.messageType,
                    );
                  },
                ),
              ),
              if (_isPartnerTyping)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: TypingIndicator(),
                ),
            ],
          );
        }

        // Default empty state when no messages are available
        return const Center(child: Text('No messages yet'));
      },
    );
  }
}
