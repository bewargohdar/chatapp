import 'package:chatapp/core/helper/app_bar.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: mainAppBar(context, "FlutterChat"),
      body: const Center(
        child: Text('Splash Screen'),
      ),
    );
  }
}
