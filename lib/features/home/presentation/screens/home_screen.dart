import 'package:chatapp/features/auth/domain/entity/user.dart';
import 'package:chatapp/features/chat/presentation/screens/chat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  List<UserEntity> _users = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = _auth.currentUser;
      final usersCollection = await _firestore.collection('users').get();

      setState(() {
        _users = usersCollection.docs
            .map((doc) => UserEntity(
                  id: doc.id,
                  email: doc['email'],
                  username: doc['username'],
                  image: doc.data().containsKey('image') ? doc['image'] : null,
                ))
            .where(
                (user) => user.id != currentUser?.uid) // Exclude current user
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _navigateToChat(UserEntity user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(selectedUser: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUsers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (_users.isEmpty) {
      return const Center(child: Text('No users found'));
    } else {
      return ListView.separated(
        itemCount: _users.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final user = _users[index];
          return ListTile(
            onTap: () => _navigateToChat(user),
            leading: CircleAvatar(
              backgroundImage:
                  user.image != null ? NetworkImage(user.image!) : null,
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
        },
      );
    }
  }
}
