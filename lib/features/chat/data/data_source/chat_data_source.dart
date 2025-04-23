import 'package:chatapp/features/chat/data/models/message.dart';
import 'package:chatapp/features/chat/domain/entity/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatapp/core/res/data_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

abstract class ChatDataSource {
  Stream<DataState<List<MessageModel>>> fetchMessages(String? recipientId);
  Future<DataState<void>> sendMessage(MessageModel message);
}

class ChatDataSourceImpl implements ChatDataSource {
  final FirebaseFirestore _firestore;

  ChatDataSourceImpl(this._firestore);

  @override
  Stream<DataState<List<MessageModel>>> fetchMessages(String? recipientId) {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        return Stream.value(DataError(Exception('User not authenticated')));
      }

      // Simple query for all messages, sorted by creation time
      var query = _firestore
          .collection('chat')
          .orderBy('createdAt', descending: true)
          .limit(50);

      // If a specific conversation is requested, we'll filter in memory after fetching
      return query.snapshots().map((snapshot) {
        final messages = snapshot.docs.map((doc) {
          return MessageModel.fromFirebase(doc.data() as Map<String, dynamic>);
        }).toList();
        // If recipientId is provided, filter messages in memory
        if (recipientId != null) {
          messages.removeWhere((message) =>
              !((message.userId == currentUserId &&
                      message.recipientId == recipientId) ||
                  (message.userId == recipientId &&
                      message.recipientId == currentUserId)));
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
      if (kDebugMode) {
        print('Error sending message: $e');
      }
      // Return error state in case of exceptions
      return DataError(Exception('Failed to send message: $e'));
    }
  }
}
