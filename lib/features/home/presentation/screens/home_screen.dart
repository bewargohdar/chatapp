import 'package:chatapp/features/auth/domain/entity/user.dart';
import 'package:chatapp/features/chat/presentation/screens/chat.dart';
import 'package:chatapp/features/home/presentation/bloc/home_bloc.dart';
import 'package:chatapp/features/home/presentation/bloc/home_event.dart';
import 'package:chatapp/features/home/presentation/bloc/home_state.dart';
import 'package:chatapp/features/home/presentation/widget/user_list_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search users...',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (query) {
                context.read<HomeBloc>().add(SearchUsersEvent(query));
              },
            ),
          ),
        ),
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          // Load users when the screen is first built
          if (state is HomeInitialState) {
            context.read<HomeBloc>().add(LoadUsersEvent());
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HomeLoadingState) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is HomeErrorState) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<HomeBloc>().add(RefreshUsersEvent()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is HomeLoadedState) {
            final users = state.users;
            if (users.isEmpty) {
              return const Center(child: Text('No users found'));
            } else {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<HomeBloc>().add(RefreshUsersEvent());
                },
                child: ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return UserListItem(
                      user: user,
                      onTap: () => _navigateToChat(context, user),
                    );
                  },
                ),
              );
            }
          }

          // Default fallback
          return const Center(child: Text('Something went wrong'));
        },
      ),
    );
  }

  void _navigateToChat(BuildContext context, UserEntity user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(selectedUser: user),
      ),
    );
  }
}
