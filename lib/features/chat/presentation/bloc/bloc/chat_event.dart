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
