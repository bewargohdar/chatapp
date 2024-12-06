import 'package:chatapp/features/chat/domain/entity/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel extends MessageEntity {
  MessageModel({
    required super.userId,
    required super.text,
    required super.username,
    required super.imageUrl,
    required super.createdAt,
  });

  factory MessageModel.fromFirebase(Map<String, dynamic> json) {
    return MessageModel(
      userId: json['userId'] ?? '',
      text: json['text'] ?? '',
      username: json['username'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirebase() {
    return {
      'userId': super.userId,
      'text': super.text,
      'username': super.username,
      'imageUrl': super.imageUrl,
      'createdAt': super.createdAt,
    };
  }
}
