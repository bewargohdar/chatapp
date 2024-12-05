import 'package:chatapp/features/chat/domain/entity/message.dart';

abstract class ChatRepository {
  Stream<List<MessageEntity>> getMessages();
  Future<void> sendMessage(MessageEntity message);
}
