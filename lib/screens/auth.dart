import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

final _auth = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _isLogin = true;

  void _submit() async {
    final isValid = _formKey.currentState!.validate();

    if (isValid) {
      _formKey.currentState!.save();
    }
    if (_isLogin) {
    } else {
      try {
        final userCredetials = await _auth.createUserWithEmailAndPassword(
            email: _emailController.text, password: _passwordController.text);
        print(userCredetials.user!.email);
        if (!mounted) return;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          print('The account already exists for that email.');
        }
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Authentication failed'),
            backgroundColor:
                Theme.of(context).colorScheme.error.withOpacity(0.5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                    bottom: 20, right: 20, left: 20, top: 30),
                width: 200,
                child: Image.asset('assets/images/chat.png'),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            decoration:
                                const InputDecoration(labelText: 'Email'),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            validator: (value) =>
                                value!.trim().isEmpty || !value.contains('@')
                                    ? 'Please enter a valid email address.'
                                    : null,
                            onSaved: (value) => _emailController.text = value!,
                          ),
                          TextFormField(
                            controller: _passwordController,
                            decoration:
                                const InputDecoration(labelText: 'Password'),
                            obscureText: true,
                            validator: (value) => value!.isEmpty ||
                                    value.trim().length < 6
                                ? 'Password must be at least 6 characters long.'
                                : null,
                            onSaved: (value) =>
                                _passwordController.text = value!,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                foregroundColor:
                                    Theme.of(context).colorScheme.primary),
                            child: Text(_isLogin ? 'Login' : 'Signup'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLogin = !_isLogin;
                              });
                            },
                            child: Text(_isLogin
                                ? 'Create new account'
                                : 'I already have an account'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
