import 'package:flutter/material.dart';

class ProfileImage extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback? onTap;
  final double size;

  const ProfileImage({
    super.key,
    this.imageUrl,
    this.onTap,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: size / 2,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.2),
            backgroundImage:
                imageUrl != null ? _getImageProvider(imageUrl!) : null,
            child: imageUrl == null
                ? Icon(
                    Icons.person,
                    size: size / 2,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
          ),
          if (onTap != null)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
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
