class MessageEntity {
  final String text;
  final String userId;
  final String username;
  final String imageUrl;
  final DateTime createdAt;
  final String? recipientId;
  final String? voiceUrl;
  final MessageType messageType;

  MessageEntity({
    required this.text,
    required this.userId,
    required this.username,
    required this.imageUrl,
    required this.createdAt,
    this.recipientId,
    this.voiceUrl,
    this.messageType = MessageType.text,
  });
}

enum MessageType {
  text,
  voice,
  image,
}
