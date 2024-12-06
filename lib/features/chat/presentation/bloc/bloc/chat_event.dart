import 'package:equatable/equatable.dart';
import 'package:chatapp/features/chat/data/models/message.dart';

abstract class ChatEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class FetchMessagesEvent extends ChatEvent {}

class SendMessageEvent extends ChatEvent {
  final MessageModel message;

  SendMessageEvent(this.message);

  @override
  List<Object> get props => [message];
}
