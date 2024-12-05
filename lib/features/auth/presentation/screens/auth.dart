import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../bloc/auth_bloc.dart';
import '../widget/auth_card.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  XFile? _selectedImage;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate() ||
        (!_isLogin && _selectedImage == null)) {
      _showMessage('Please complete the form.');
      return;
    }

    _formKey.currentState!.save();

    if (_isLogin) {
      _loginUser();
    } else {
      _registerUser();
    }
  }

  void _loginUser() {
    context.read<AuthBloc>().add(AuthLogin(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        ));
  }

  Future<void> _registerUser() async {
    context.read<AuthBloc>().add(AuthRegister(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _usernameController.text.trim(),
          _selectedImage!,
        ));
  }

  void _showMessage(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            _showMessage(state.message, backgroundColor: Colors.red);
          } else if (state is AuthSuccess) {
            _showMessage('Authentication Successful',
                backgroundColor: Colors.green);
          }
        },
        builder: (context, state) {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LogoSection(),
                  AuthCard(
                    isLogin: _isLogin,
                    formKey: _formKey,
                    emailController: _emailController,
                    usernameController: _usernameController,
                    passwordController: _passwordController,
                    onImagePicked: (image) => _selectedImage = image,
                    onSubmit: _submit,
                    onToggleAuthMode: _toggleAuthMode,
                    isLoading: state is AuthLoading,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LogoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20, right: 20, left: 20, top: 30),
      width: 200,
      child: Image.asset('assets/images/chat.png'),
    );
  }
}
