import 'package:chatapp/features/chat/domain/entity/message.dart';
import 'package:equatable/equatable.dart';

abstract class ChatState extends Equatable {
  @override
  List<Object> get props => [];
}

class ChatInitialState extends ChatState {}

class ChatLoadingState extends ChatState {}

class ChatMessagesFetchedState extends ChatState {
  final List<MessageEntity> messages;
  final bool isTyping;

  ChatMessagesFetchedState(this.messages, {this.isTyping = false});

  @override
  List<Object> get props => [messages, isTyping];
}

class ChatMessageSentState extends ChatState {}

class ChatErrorState extends ChatState {
  final String message;

  ChatErrorState(this.message);

  @override
  List<Object> get props => [message];
}

class VoiceRecordingStartedState extends ChatState {}

class VoiceRecordingStoppedState extends ChatState {}

class VoiceRecordingCanceledState extends ChatState {}

class VoiceSendingState extends ChatState {}

class VoiceSentState extends ChatState {}

class UserTypingState extends ChatState {
  final bool isTyping;
  final String? userId;

  UserTypingState({required this.isTyping, this.userId});

  @override
  List<Object> get props => [isTyping, if (userId != null) userId!];
}
