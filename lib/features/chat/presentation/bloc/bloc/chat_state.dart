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

  ChatMessagesFetchedState(this.messages);

  @override
  List<Object> get props => [messages];
}

class ChatMessageSentState extends ChatState {}

class ChatErrorState extends ChatState {
  final String message;

  ChatErrorState(this.message);

  @override
  List<Object> get props => [message];
}
