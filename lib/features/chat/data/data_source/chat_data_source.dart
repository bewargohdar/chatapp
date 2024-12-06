import 'package:chatapp/features/chat/data/models/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatapp/core/res/data_state.dart';

abstract class ChatDataSource {
  Stream<DataState<List<MessageModel>>> fetchMessages();
  Future<DataState<void>> sendMessage(MessageModel message);
}

class ChatDataSourceImpl implements ChatDataSource {
  final FirebaseFirestore _firestore;

  ChatDataSourceImpl(this._firestore);
  @override
  Stream<DataState<List<MessageModel>>> fetchMessages() {
    try {
      return _firestore
          .collection('chat')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        final messages = snapshot.docs.map((doc) {
          return MessageModel.fromFirebase(doc.data());
        }).toList();

        if (messages.isEmpty) {
          return DataError(Exception('No messages found'));
        }

        return DataSuccess(messages);
      });
    } catch (e) {
      return Stream.value(DataError(Exception('Failed to fetch messages: $e')));
    }
  }

  @override
  Future<DataState<void>> sendMessage(MessageModel message) async {
    try {
      final data =
          await _firestore.collection('chat').add(message.toFirebase());

      return DataSuccess(data);
    } catch (e) {
      // Return error state in case of exceptions
      return DataError(Exception('Failed to send message: $e'));
    }
  }
}
