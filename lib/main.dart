import 'package:chatapp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chatapp/features/chat/presentation/bloc/bloc/chat_bloc.dart';
import 'package:chatapp/features/chat/presentation/bloc/bloc/chat_event.dart';
import 'package:chatapp/features/home/presentation/bloc/home_bloc.dart';
import 'package:chatapp/features/home/presentation/screens/home_screen.dart';

import 'package:chatapp/features/splash.dart';
import 'package:chatapp/firebase_options.dart';
import 'package:chatapp/features/auth/presentation/screens/auth.dart';
import 'package:chatapp/server_injection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize dependency injection
  init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<AuthBloc>(),
        ),
        BlocProvider(
          create: (context) => sl<ChatBloc>()..add(FetchMessagesEvent()),
        ),
        BlocProvider(
          create: (context) => sl<HomeBloc>(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FlutterChat',
        theme: ThemeData().copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.black,
            primary: Colors.deepPurple,
            secondary: Colors.deepPurpleAccent,
          ),
        ),
        home: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }
            if (snapshot.hasData) {
              return const HomeScreen();
            } else {
              return const AuthScreen();
            }
          },
        ),
      ),
    );
  }
}
