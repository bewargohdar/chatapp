import 'package:chatapp/features/chat/domain/entity/message.dart';

class MessageModel extends MessageEntity {
  MessageModel({
    required super.id,
    required super.userId,
    required super.text,
    required super.username,
    required super.imageUrl,
    required super.createdAt,
  });

  factory MessageModel.fromFirebase(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      userId: json['senderId'],
      text: json['message'],
      username: json['username'],
      imageUrl: json['imageUrl'],
      createdAt: json['timestamp'].toDate(),
    );
  }

  Map<String, dynamic> toFirebase() {
    return {
      'id': super.id,
      'senderId': super.userId,
      'message': super.text,
      'username': super.username,
      'imageUrl': super.imageUrl,
      'timestamp': super.createdAt,
    };
  }
}
