import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatMessages extends StatelessWidget {
  const ChatMessages({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No messages yet'),
          );
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text('An error occurred'),
          );
        }
        return ListView.builder(
          itemBuilder: (context, index) {
            final chatData = snapshot.data!.docs[index];
            return Text(chatData['text']);
          },
          itemCount: snapshot.data!.docs.length,
        );
      },
      stream: FirebaseFirestore.instance
          .collection('chat')
          .orderBy('createdAt', descending: false)
          .snapshots(),
    );
  }
}
