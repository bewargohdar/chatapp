class MessageEntity {
  final String id;
  final String text;
  final String userId;
  final String username;
  final String imageUrl;
  final DateTime createdAt;

  MessageEntity({
    required this.id,
    required this.text,
    required this.userId,
    required this.username,
    required this.imageUrl,
    required this.createdAt,
  });
}
