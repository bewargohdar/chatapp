import 'package:chatapp/features/chat/domain/entity/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel extends MessageEntity {
  MessageModel({
    required super.userId,
    required super.text,
    required super.username,
    required super.imageUrl,
    required super.createdAt,
    super.recipientId,
    super.voiceUrl,
    super.messageType = MessageType.text,
  });

  factory MessageModel.fromFirebase(Map<String, dynamic> json) {
    int messageTypeIndex = json['messageType'] ?? -1;
    MessageType messageType =
        (messageTypeIndex >= 0 && messageTypeIndex < MessageType.values.length)
            ? MessageType.values[messageTypeIndex]
            : MessageType.text;

    return MessageModel(
      userId: json['userId'] ?? '',
      text: json['text'] ?? '',
      username: json['username'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      recipientId: json['recipientId'],
      voiceUrl: json['voiceUrl'],
      messageType: messageType,
    );
  }

  Map<String, dynamic> toFirebase() {
    return {
      'userId': super.userId,
      'text': super.text,
      'username': super.username,
      'imageUrl': super.imageUrl,
      'createdAt': super.createdAt,
      'recipientId': super.recipientId,
      'voiceUrl': super.voiceUrl,
      'messageType': super.messageType.index,
    };
  }
}
