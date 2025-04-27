import 'package:chatapp/features/chat/data/models/message.dart';
import 'package:chatapp/features/chat/domain/entity/message.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatapp/core/res/data_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:chatapp/core/services/notification_service.dart';

abstract class ChatDataSource {
  Stream<DataState<List<MessageModel>>> fetchMessages(String? recipientId);
  Future<DataState<void>> sendMessage(MessageModel message);
}

class ChatDataSourceImpl implements ChatDataSource {
  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;

  ChatDataSourceImpl(this._firestore, this._notificationService);

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
          return MessageModel.fromFirebase(doc.data());
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

      // After successfully sending the message, send a notification
      await _sendNotification(message);

      return DataSuccess(data);
    } catch (e) {
      if (kDebugMode) {
        print('Error sending message: $e');
      }
      // Return error state in case of exceptions
      return DataError(Exception('Failed to send message: $e'));
    }
  }

  Future<void> _sendNotification(MessageModel message) async {
    try {
      // Get recipient user data to get their FCM token
      final recipientDoc =
          await _firestore.collection('users').doc(message.recipientId).get();

      if (recipientDoc.exists) {
        final recipientData = recipientDoc.data();
        if (recipientData != null) {
          final fcmToken = recipientData['fcmToken'];

          if (fcmToken != null) {
            // Get sender info to display in notification
            final senderDoc =
                await _firestore.collection('users').doc(message.userId).get();

            final senderName = senderDoc.exists && senderDoc.data() != null
                ? senderDoc.data()!['displayName'] ?? 'Someone'
                : 'Someone';

            // Send notification
            await _notificationService.sendNotification(
              recipientToken: fcmToken,
              title: senderName,
              body: message.messageType == MessageType.text
                  ? message.text
                  : '${message.messageType.toString().split('.').last} message',
              data: {
                'senderId': message.userId,
                'recipientId': message.recipientId,
                'type': 'chat_message',
              },
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending notification: $e');
      }
      // Don't throw error here, just log it
      // The message was still sent successfully
    }
  }
}
