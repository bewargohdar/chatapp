import 'package:flutter/material.dart';

class ChatMessages extends StatelessWidget {
  const ChatMessages({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: Text('Hello'),
          subtitle: Text('This is a message'),
          trailing: const CircleAvatar(
            child: Text('A'),
          ),
        ),
      ],
    );
  }
}
