import 'package:chatapp/core/res/data_state.dart';
import 'package:chatapp/features/chat/data/models/message.dart';
import 'package:chatapp/features/chat/domain/entity/message.dart';

abstract class ChatRepository {
  Future<DataState<List<MessageEntity>>> getMessages();
  Future<DataState> sendMessage(MessageModel message);
}
