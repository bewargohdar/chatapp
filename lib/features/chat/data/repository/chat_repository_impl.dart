import 'package:chatapp/core/res/data_state.dart';
import 'package:chatapp/features/chat/data/data_source/chat_data_source.dart';
import 'package:chatapp/features/chat/data/models/message.dart';

import 'package:chatapp/features/chat/domain/repesotiry/chat_repository.dart';

class ChatRepositoryImpl extends ChatRepository {
  final ChatDataSource _dataSource;

  ChatRepositoryImpl(this._dataSource);
  @override
  Stream<DataState<List<MessageModel>>> getMessages(String? recipientId) {
    return _dataSource.fetchMessages(recipientId);
  }

  @override
  Future<DataState<void>> sendMessage(MessageModel message) {
    return _dataSource.sendMessage(message);
  }
}
