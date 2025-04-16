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
    return MessageModel(
      userId: json['userId'] ?? '',
      text: json['text'] ?? '',
      username: json['username'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      recipientId: json['recipientId'],
      voiceUrl: json['voiceUrl'],
      messageType: json['messageType'] != null
          ? MessageType.values[json['messageType']]
          : MessageType.text,
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
