import 'dart:io';

import 'package:chatapp/features/auth/data/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chatapp/core/services/notification_service.dart';
import 'package:chatapp/server_injection.dart';

import '../../../../core/res/data_state.dart';

abstract class AuthRemoteDataSource {
  Future<DataState<UserModel>> login(String email, String password);
  Future<DataState<UserModel>> signup(
      String email, String password, String username, XFile image);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationService _notificationService = sl<NotificationService>();

  @override
  Future<DataState<UserModel>> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save FCM token for the user
      await _notificationService.saveToken(userCredential.user!.uid);

      return DataSuccess(
        UserModel(
          id: userCredential.user!.uid,
          email: userCredential.user!.email!,
        ),
      );
    } on FirebaseAuthException catch (e) {
      return DataError(e);
    }
  }

  @override
  Future<DataState<UserModel>> signup(
    String email,
    String password,
    String username,
    XFile image,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user!.uid;

      // Upload image
      final storageRef =
          _storage.ref().child('user_images').child('$userId.jpg');
      final uploadTask = await storageRef.putFile(File(image.path));
      final imageUrl = await uploadTask.ref.getDownloadURL();

      // Get FCM token
      final fcmToken = await _notificationService.getToken();

      // Save additional data including FCM token
      await _firestore.collection('users').doc(userId).set({
        'username': username,
        'email': email,
        'image': imageUrl,
        'fcmToken': fcmToken,
      });

      return DataSuccess(UserModel(id: userId, email: email));
    } on FirebaseAuthException catch (e) {
      return DataError(e);
    } catch (e) {
      // Add generic error handling to catch any other exceptions
      return DataError(Exception('Registration failed: $e'));
    }
  }
}
