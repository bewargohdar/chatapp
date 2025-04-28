import 'package:chatapp/features/auth/domain/entity/user.dart';
import 'package:flutter/material.dart';

class UserListItem extends StatelessWidget {
  final UserEntity user;
  final VoidCallback onTap;

  const UserListItem({
    super.key,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundImage:
            user.image != null ? _getImageProvider(user.image!) : null,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: user.image == null
            ? Text(
                user.username?.substring(0, 1).toUpperCase() ??
                    user.email.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(user.username ?? user.email),
      subtitle: user.username != null ? Text(user.email) : null,
    );
  }

  // Helper method to safely create an image provider - same as in MessageBubble
  ImageProvider _getImageProvider(String imageUrl) {
    if (imageUrl.isEmpty) {
      return const AssetImage('assets/images/chat.png');
    }

    try {
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        return NetworkImage(imageUrl);
      } else if (imageUrl.startsWith('assets/')) {
        return AssetImage(imageUrl);
      } else {
        // If URL is not empty but doesn't have a protocol, add https://
        return NetworkImage('https://$imageUrl');
      }
    } catch (e) {
      print('Error creating image provider: $e');
      // Fallback to default image
      return const AssetImage('assets/images/chat.png');
    }
  }
}
