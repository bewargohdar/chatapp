import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chatapp/features/chat/data/models/message.dart';
import 'package:chatapp/features/chat/domain/entity/message.dart';

class UserMessageService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get current user data
  Future<Map<String, dynamic>> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final userData = await _firestore.collection('users').doc(user.uid).get();
    if (!userData.exists || userData.data() == null) {
      throw Exception('User data not found');
    }

    return {
      'userId': user.uid,
      'username': userData.data()?['username'] ?? 'Anonymous',
      'imageUrl': userData.data()?['image'] ?? '',
    };
  }

  // Create text message
  Future<MessageModel> createTextMessage(
      String text, String? recipientId) async {
    final userData = await getCurrentUserData();
    return MessageModel(
      userId: userData['userId'],
      text: text,
      username: userData['username'],
      imageUrl: userData['imageUrl'],
      createdAt: DateTime.now(),
      recipientId: recipientId,
      messageType: MessageType.text,
    );
  }

  // Upload image and create image message
  Future<MessageModel> createImageMessage(
      XFile image, String? recipientId) async {
    final userData = await getCurrentUserData();

    // Upload image file to Firebase Storage
    final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storageRef = _storage.ref().child('chat_images').child(fileName);

    final File file = File(image.path);
    final uploadTask = await storageRef.putFile(file);
    final String imageDownloadUrl = await uploadTask.ref.getDownloadURL();

    return MessageModel(
      userId: userData['userId'],
      text: '', // No text for image message
      username: userData['username'],
      imageUrl: userData['imageUrl'], // User's profile image
      createdAt: DateTime.now(),
      recipientId: recipientId,
      messageType: MessageType.image,
      voiceUrl: imageDownloadUrl, // Using voiceUrl field to store image URL
    );
  }

  // Create voice message with URL
  Future<MessageModel> createVoiceMessage(
      String voiceUrl, String? recipientId) async {
    final userData = await getCurrentUserData();
    return MessageModel(
      userId: userData['userId'],
      text: '🎤 Voice message',
      username: userData['username'],
      imageUrl: userData['imageUrl'],
      createdAt: DateTime.now(),
      recipientId: recipientId,
      voiceUrl: voiceUrl,
      messageType: MessageType.voice,
    );
  }

  // Set user typing status
  Future<void> setTypingStatus(String? recipientId, bool isTyping) async {
    final user = _auth.currentUser;
    if (user == null || recipientId == null) {
      return;
    }

    // Create a unique chat ID to track typing (smaller ID first for consistency)
    final chatId = user.uid.compareTo(recipientId) < 0
        ? '${user.uid}_$recipientId'
        : '${recipientId}_${user.uid}';

    try {
      await _firestore.collection('typing_status').doc(chatId).set({
        user.uid: isTyping,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating typing status: $e');
    }
  }

  // Listen to typing status
  Stream<bool> getTypingStatus(String? userId) {
    final user = _auth.currentUser;
    if (user == null || userId == null) {
      return Stream.value(false);
    }

    // Create a unique chat ID to track typing (smaller ID first for consistency)
    final chatId = user.uid.compareTo(userId) < 0
        ? '${user.uid}_$userId'
        : '${userId}_${user.uid}';

    return _firestore
        .collection('typing_status')
        .doc(chatId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return false;
      final data = snapshot.data();
      return data?[userId] == true;
    });
  }
}
