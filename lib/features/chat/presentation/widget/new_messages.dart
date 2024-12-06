import 'package:chatapp/features/chat/presentation/bloc/bloc/chat_bloc.dart';
import 'package:chatapp/features/chat/presentation/bloc/bloc/chat_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chatapp/features/chat/data/models/message.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewMessages extends StatefulWidget {
  const NewMessages({super.key});

  @override
  State<NewMessages> createState() => _NewMessagesState();
}

class _NewMessagesState extends State<NewMessages> {
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final enteredMessage = _messageController.text.trim();

    if (enteredMessage.isEmpty) {
      return;
    }

    if (_isSending) return; // Prevent multiple submissions

    setState(() {
      _isSending = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to send messages')),
          );
        }
        return;
      }

      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userData.exists || userData.data() == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User data not found')),
          );
        }
        return;
      }

      final username =
          userData.data()?['username'] ?? 'Anonymous'; // Default value if null
      final imageUrl =
          userData.data()?['image_url'] ?? ''; // Default empty string if null

      // Create MessageModel and send it through the BLoC
      final message = MessageModel(
        userId: user.uid,
        text: enteredMessage,
        username: username,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );
      if (mounted) {
        context.read<ChatBloc>().add(SendMessageEvent(message));
      }

      // Clear input after sending message
      _messageController.clear();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 1, bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              autocorrect: true,
              enableSuggestions: true,
              decoration: InputDecoration(
                labelText: 'Send a message...',
                suffixIcon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
