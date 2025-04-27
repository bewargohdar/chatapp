import 'package:chatapp/features/auth/domain/entity/user.dart';
import 'package:chatapp/core/services/user_message_service.dart';
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

class _NewMessagesState extends State<NewMessages>
    with SingleTickerProviderStateMixin {
  final _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final UserMessageService _userMessageService =
      GetIt.instance<UserMessageService>();

  // Animation controller for recording animation
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Voice control methods
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
    if (enteredMessage.isEmpty) return;

    try {
      final message = await _userMessageService.createTextMessage(
        enteredMessage,
        widget.selectedUser?.id,
      );

      if (mounted) {
        context.read<ChatBloc>().add(SendMessageEvent(message));
        _messageController.clear();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $error')),
        );
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
    try {
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
            const SnackBar(
              content: Text('Voice message sent'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Start or stop the animation based on recording state
        if (state is VoiceRecordingStartedState) {
          _animationController.repeat(reverse: true);
        } else if (state is VoiceRecordingStoppedState ||
            state is VoiceRecordingCanceledState) {
          _animationController.stop();
        }
      },
      builder: (context, state) {
        final bool isRecording = state is VoiceRecordingStartedState;
        final bool isSending = state is VoiceSendingState;
        final primaryColor = Theme.of(context).colorScheme.primary;
        final secondaryColor = Theme.of(context).colorScheme.secondary;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                offset: const Offset(0, -1),
                blurRadius: 6,
              ),
            ],
          ),
          child: Row(
            children: [
              // Voice recording/cancellation area
              if (isRecording)
                Expanded(
                  child: GestureDetector(
                    onHorizontalDragEnd: (_) => _cancelVoiceRecording(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Animated recording indicator
                          AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.5),
                                      blurRadius: 5.0 * _pulseAnimation.value,
                                      spreadRadius: 2.0 * _pulseAnimation.value,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Recording...',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Release to send, slide left to cancel',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Icon(
                            Icons.keyboard_arrow_left,
                            color: primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: TextFormField(
                        controller: _messageController,
                        textCapitalization: TextCapitalization.sentences,
                        autocorrect: true,
                        enabled: !isRecording,
                        enableSuggestions: true,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: widget.selectedUser != null
                              ? 'Message to ${widget.selectedUser!.username ?? widget.selectedUser!.email}'
                              : 'Send a message...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          suffixIcon: isSending
                              ? Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: primaryColor,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.attach_file),
                                  onPressed: _pickImage,
                                  color: secondaryColor,
                                  iconSize: 22,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(width: 8),

              // Action button (send or voice record)
              if (isRecording)
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: primaryColor,
                    elevation: 4,
                    child:
                        const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _stopVoiceRecording,
                  ),
                )
              else
                Row(
                  children: [
                    // Send button
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: FloatingActionButton(
                        mini: true,
                        backgroundColor: primaryColor,
                        elevation: 4,
                        child: const Icon(Icons.send,
                            color: Colors.white, size: 20),
                        onPressed: () {
                          final text = _messageController.text.trim();
                          if (text.isNotEmpty) {
                            _sendMessage();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a message'),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                    ),

                    // Add mic button for voice recording
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: secondaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: GestureDetector(
                        onLongPress: _startVoiceRecording,
                        onLongPressUp: _stopVoiceRecording,
                        child: FloatingActionButton(
                          mini: true,
                          backgroundColor: secondaryColor,
                          elevation: 4,
                          child: const Icon(Icons.mic,
                              color: Colors.white, size: 20),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Hold to record a voice message'),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
