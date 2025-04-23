import 'package:chatapp/features/auth/domain/entity/user.dart';
import 'package:chatapp/features/chat/data/services/user_message_service.dart';
import 'package:chatapp/features/chat/presentation/bloc/bloc/chat_bloc.dart';
import 'package:chatapp/features/chat/presentation/bloc/bloc/chat_event.dart';
import 'package:chatapp/features/chat/presentation/bloc/bloc/chat_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_it/get_it.dart';

class NewMessages extends StatefulWidget {
  final UserEntity? selectedUser;

  const NewMessages({
    super.key,
    this.selectedUser,
  });

  @override
  State<NewMessages> createState() => _NewMessagesState();
}

class _NewMessagesState extends State<NewMessages> {
  final _messageController = TextEditingController();
  bool _isSending = false;
  final ImagePicker _picker = ImagePicker();
  final UserMessageService _userMessageService =
      GetIt.instance<UserMessageService>();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // Voice control methods that dispatch events to the bloc
  void _startVoiceRecording() {
    context.read<ChatBloc>().add(StartRecordingVoiceEvent());
  }

  void _stopVoiceRecording() {
    context.read<ChatBloc>().add(StopRecordingVoiceEvent(
          recipient: widget.selectedUser,
        ));
  }

  void _cancelVoiceRecording() {
    context.read<ChatBloc>().add(CancelRecordingVoiceEvent());
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
      // Create and send text message through the service
      final message = await _userMessageService.createTextMessage(
        enteredMessage,
        widget.selectedUser?.id,
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

  Future<void> _pickImage() async {
    final XFile? pickedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      await _sendImageMessage(pickedImage);
    }
  }

  Future<void> _sendImageMessage(XFile image) async {
    if (_isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      // Create and send image message through the service
      final message = await _userMessageService.createImageMessage(
        image,
        widget.selectedUser?.id,
      );

      if (mounted) {
        context.read<ChatBloc>().add(SendMessageEvent(message));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send image message: $error')),
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
    return BlocConsumer<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state is ChatErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }

        if (state is VoiceSentState) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Voice message sent')),
          );
        }
      },
      builder: (context, state) {
        bool isRecording = state is VoiceRecordingStartedState;
        bool isSending = _isSending || state is VoiceSendingState;

        return Padding(
          padding: const EdgeInsets.only(left: 15, right: 1, bottom: 14),
          child: Row(
            children: [
              // Voice recording button
              isRecording
                  ? Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _stopVoiceRecording,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel),
                          onPressed: _cancelVoiceRecording,
                          color: Colors.red,
                        ),
                        const Text('Recording...',
                            style: TextStyle(color: Colors.red)),
                      ],
                    )
                  : IconButton(
                      icon: const Icon(Icons.mic),
                      onPressed: _startVoiceRecording,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              // Text input field
              Expanded(
                child: TextFormField(
                  controller: _messageController,
                  textCapitalization: TextCapitalization.sentences,
                  autocorrect: true,
                  enabled: !isRecording,
                  enableSuggestions: true,
                  decoration: InputDecoration(
                    labelText: isRecording
                        ? 'Recording voice message...'
                        : widget.selectedUser != null
                            ? 'Message to ${widget.selectedUser!.username ?? widget.selectedUser!.email}'
                            : 'Send a message...',
                    suffixIcon: isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                  ),
                ),
              ),
              // Send button
              if (!isRecording)
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Theme.of(context).colorScheme.primary,
                ),
              IconButton(
                icon: const Icon(Icons.image),
                onPressed: _pickImage,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ],
          ),
        );
      },
    );
  }
}
