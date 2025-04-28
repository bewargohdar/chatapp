import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meta/meta.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../auth/domain/entity/user.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  ProfileBloc() : super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfileUsername>(_onUpdateUsername);
    on<UpdateProfileImage>(_onUpdateImage);
  }

  Future<void> _onLoadProfile(
      LoadProfile event, Emitter<ProfileState> emit) async {
    try {
      emit(ProfileLoading());

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        emit(const ProfileError('User not authenticated'));
        return;
      }

      final userData =
          await _firestore.collection('users').doc(currentUser.uid).get();

      print("Loaded user data: ${userData.data()}");

      if (!userData.exists) {
        emit(const ProfileError('User data not found'));
        return;
      }

      final data = userData.data()!;

      final user = UserEntity(
        id: currentUser.uid,
        email: data['email'] ?? currentUser.email ?? '',
        username: data['username'],
        image: data['image'], // Changed from 'imageUrl' to 'image'
      );

      print(
          "Parsed user: id=${user.id}, email=${user.email}, username=${user.username}, image=${user.image}");

      emit(ProfileLoaded(user));
    } catch (e) {
      print("Error loading profile: $e");
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onUpdateUsername(
      UpdateProfileUsername event, Emitter<ProfileState> emit) async {
    try {
      final currentState = state;
      if (currentState is ProfileLoaded) {
        emit(ProfileLoading());

        final currentUser = _auth.currentUser;
        if (currentUser == null) {
          emit(const ProfileError('User not authenticated'));
          return;
        }

        await _firestore.collection('users').doc(currentUser.uid).update({
          'username': event.username,
        });

        final updatedUser = UserEntity(
          id: currentState.user.id,
          email: currentState.user.email,
          username: event.username,
          image: currentState.user.image,
        );

        emit(ProfileUpdateSuccess());
        emit(ProfileLoaded(updatedUser));
      }
    } catch (e) {
      emit(ProfileError(e.toString()));
      add(LoadProfile());
    }
  }

  Future<void> _onUpdateImage(
      UpdateProfileImage event, Emitter<ProfileState> emit) async {
    try {
      final currentState = state;
      if (currentState is ProfileLoaded) {
        emit(ProfileLoading());

        final currentUser = _auth.currentUser;
        if (currentUser == null) {
          emit(const ProfileError('User not authenticated'));
          return;
        }

        final file = File(event.image.path);
        final ref =
            _storage.ref().child('user_images').child('${currentUser.uid}.jpg');

        // Upload the file with metadata
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'userId': currentUser.uid},
        );
        await ref.putFile(file, metadata);

        final imageUrl = await ref.getDownloadURL();
        print("Image uploaded successfully. URL: $imageUrl");

        await _firestore.collection('users').doc(currentUser.uid).update({
          'image': imageUrl, // Changed from 'imageUrl' to 'image'
        });

        // Verify the update was successful
        final userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();
        print("After update, image = ${userDoc.data()?['image']}");

        final updatedUser = UserEntity(
          id: currentState.user.id,
          email: currentState.user.email,
          username: currentState.user.username,
          image: imageUrl,
        );

        emit(ProfileUpdateSuccess());
        emit(ProfileLoaded(updatedUser));
      }
    } catch (e) {
      print("Error updating image: $e");
      emit(ProfileError(e.toString()));
      add(LoadProfile());
    }
  }
}
