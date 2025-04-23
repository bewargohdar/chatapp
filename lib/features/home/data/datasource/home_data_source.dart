import 'package:chatapp/core/res/data_state.dart';
import 'package:chatapp/features/auth/domain/entity/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class HomeDataSource {
  Future<DataState<List<UserEntity>>> getUsers([String? query]);
}

class HomeDataSourceImpl implements HomeDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  HomeDataSourceImpl(this._firestore, this._auth);

  @override
  Future<DataState<List<UserEntity>>> getUsers([String? query]) async {
    try {
      final currentUser = _auth.currentUser;
      final usersCollection = await _firestore.collection('users').get();

      final users = usersCollection.docs
          .map((doc) => UserEntity(
                id: doc.id,
                email: doc['email'],
                username: doc['username'],
                image: doc.data().containsKey('image') ? doc['image'] : null,
              ))
          .where((user) => user.id != currentUser?.uid) // Exclude current user
          .where((user) =>
              query == null ||
              user.username?.contains(query) == true) // Filter by query
          .toList();

      return DataSuccess(users);
    } catch (e) {
      return DataError(Exception(e.toString()));
    }
  }
}
