import 'dart:io';
import 'package:chatapp/features/auth/domain/entity/user.dart';
import 'package:chatapp/features/chat/presentation/bloc/bloc/chat_bloc.dart';
import 'package:chatapp/features/chat/presentation/bloc/bloc/chat_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chatapp/features/chat/data/models/message.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:another_audio_recorder/another_audio_recorder.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:chatapp/features/chat/domain/entity/message.dart';
import 'package:image_picker/image_picker.dart';

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
  bool _isRecording = false;
  AnotherAudioRecorder? _recorder;
  String? _recordingPath;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _messageController.dispose();
    _stopRecording();
    super.dispose();
  }

  Future<bool> _checkPermission() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required')),
        );
      }
      return false;
    }
    return true;
  }

  Future<void> _startRecording() async {
    if (!await _checkPermission()) {
      return;
    }

    try {
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/voice_message_${DateTime.now().millisecondsSinceEpoch}.aac';

      _recorder = AnotherAudioRecorder(path, audioFormat: AudioFormat.AAC);
      await _recorder!.initialized;
      await _recorder!.start();

      setState(() {
        _isRecording = true;
        _recordingPath = path;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording || _recorder == null) return;

    try {
      final recording = await _recorder!.stop();
      setState(() {
        _isRecording = false;
      });

      if (recording != null) {
        await _sendVoiceMessage(recording.path!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to stop recording: $e')),
        );
      }
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _cancelRecording() async {
    if (!_isRecording || _recorder == null) return;

    try {
      await _recorder!.stop();

      if (_recordingPath != null) {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      print('Error canceling recording: $e');
    } finally {
      setState(() {
        _isRecording = false;
        _recordingPath = null;
      });
    }
  }

  Future<void> _sendVoiceMessage(String filePath) async {
    if (_isSending) return;

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

      final username = userData.data()?['username'] ?? 'Anonymous';
      final imageUrl = userData.data()?['image'] ?? '';

      // Upload voice file to Firebase Storage
      final fileName =
          'voice_message_${DateTime.now().millisecondsSinceEpoch}.aac';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('voice_messages')
          .child(fileName);

      final File file = File(filePath);
      final uploadTask = await storageRef.putFile(file);
      final voiceUrl = await uploadTask.ref.getDownloadURL();

      // Create MessageModel and send it through the BLoC
      final message = MessageModel(
        userId: user.uid,
        text: '🎤 Voice message', // Text displayed if voice player isn't shown
        username: username,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        recipientId: widget.selectedUser?.id,
        voiceUrl: voiceUrl,
        messageType: MessageType.voice,
      );

      if (mounted) {
        context.read<ChatBloc>().add(SendMessageEvent(message));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send voice message: $error')),
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
          userData.data()?['image'] ?? ''; // Default empty string if null

      // Create MessageModel and send it through the BLoC
      final message = MessageModel(
        userId: user.uid,
        text: enteredMessage,
        username: username,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        recipientId:
            widget.selectedUser?.id, // Add recipient ID if selected user exists
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

      final username = userData.data()?['username'] ?? 'Anonymous';
      final imageUrl = userData.data()?['image'] ?? '';

      // Upload image file to Firebase Storage
      final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef =
          FirebaseStorage.instance.ref().child('chat_images').child(fileName);

      final File file = File(image.path);
      final uploadTask = await storageRef.putFile(file);
      final String imageDownloadUrl = await uploadTask.ref.getDownloadURL();

      // Create MessageModel and send it through the BLoC
      final message = MessageModel(
        userId: user.uid,
        text: '', // No text for image message
        username: username,
        imageUrl: imageDownloadUrl,
        createdAt: DateTime.now(),
        recipientId: widget.selectedUser?.id,
        messageType: MessageType.image,
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
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 1, bottom: 14),
      child: Row(
        children: [
          // Voice recording button
          _isRecording
              ? Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _stopRecording,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel),
                      onPressed: _cancelRecording,
                      color: Colors.red,
                    ),
                    const Text('Recording...',
                        style: TextStyle(color: Colors.red)),
                  ],
                )
              : IconButton(
                  icon: const Icon(Icons.mic),
                  onPressed: _startRecording,
                  color: Theme.of(context).colorScheme.secondary,
                ),
          // Text input field
          Expanded(
            child: TextFormField(
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              autocorrect: true,
              enabled: !_isRecording,
              enableSuggestions: true,
              decoration: InputDecoration(
                labelText: _isRecording
                    ? 'Recording voice message...'
                    : widget.selectedUser != null
                        ? 'Message to ${widget.selectedUser!.username ?? widget.selectedUser!.email}'
                        : 'Send a message...',
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
          // Send button
          if (!_isRecording)
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _sendMessage,
              color: Theme.of(context).colorScheme.primary,
            ),
          IconButton(
            icon: Icon(Icons.image),
            onPressed: _pickImage,
          ),
        ],
      ),
    );
  }
}
