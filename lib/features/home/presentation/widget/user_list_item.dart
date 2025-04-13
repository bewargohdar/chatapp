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
        backgroundImage: user.image != null ? NetworkImage(user.image!) : null,
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
}
