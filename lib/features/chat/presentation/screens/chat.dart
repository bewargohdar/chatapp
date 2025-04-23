import 'package:chatapp/features/auth/domain/entity/user.dart';
import 'package:chatapp/features/chat/presentation/widget/chat_messages.dart';
import 'package:flutter/material.dart';

import '../../../../core/helper/app_bar.dart';
import '../widget/new_messages.dart';

class ChatScreen extends StatelessWidget {
  final UserEntity? selectedUser;

  const ChatScreen({
    super.key,
    this.selectedUser,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: mainAppBar(
        context,
        selectedUser?.username ?? "Chat",
      ),
      body: Column(
        children: [
          Expanded(child: ChatMessages(selectedUser: selectedUser)),
          NewMessages(selectedUser: selectedUser),
        ],
      ),
    );
  }
}
