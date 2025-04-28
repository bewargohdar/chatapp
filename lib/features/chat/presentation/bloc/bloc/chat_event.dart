import 'package:equatable/equatable.dart';
import 'package:chatapp/features/chat/data/models/message.dart';
import 'package:chatapp/features/auth/domain/entity/user.dart';

abstract class ChatEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class FetchMessagesEvent extends ChatEvent {
  final UserEntity? selectedUser;

  FetchMessagesEvent({this.selectedUser});

  @override
  List<Object> get props => selectedUser != null ? [selectedUser!] : [];
}

class SendMessageEvent extends ChatEvent {
  final MessageModel message;

  SendMessageEvent(this.message);

  @override
  List<Object> get props => [message];
}

class StartRecordingVoiceEvent extends ChatEvent {}

class StopRecordingVoiceEvent extends ChatEvent {
  final UserEntity? recipient;

  StopRecordingVoiceEvent({this.recipient});

  @override
  List<Object> get props => recipient != null ? [recipient!] : [];
}

class CancelRecordingVoiceEvent extends ChatEvent {}

class SendVoiceMessageEvent extends ChatEvent {
  final String filePath;
  final UserEntity? recipient;

  SendVoiceMessageEvent({
    required this.filePath,
    this.recipient,
  });

  @override
  List<Object> get props => [filePath];
}

// Add typing status events
class StartTypingEvent extends ChatEvent {
  final UserEntity? recipient;

  StartTypingEvent({this.recipient});

  @override
  List<Object> get props => recipient != null ? [recipient!] : [];
}

class StopTypingEvent extends ChatEvent {
  final UserEntity? recipient;

  StopTypingEvent({this.recipient});

  @override
  List<Object> get props => recipient != null ? [recipient!] : [];
}
