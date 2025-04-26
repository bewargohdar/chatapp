import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/helper/widget/user_image_picker.dart';

class AuthCard extends StatelessWidget {
  final bool isLogin;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final Function(XFile?) onImagePicked;
  final VoidCallback onSubmit;
  final VoidCallback onToggleAuthMode;
  final bool isLoading;

  const AuthCard({
    super.key,
    required this.isLogin,
    required this.formKey,
    required this.emailController,
    required this.usernameController,
    required this.passwordController,
    required this.onImagePicked,
    required this.onSubmit,
    required this.onToggleAuthMode,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isLogin)
                UserImagePicker(
                  onImagePicked: onImagePicked,
                ),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  suffixIcon: emailController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => emailController.clear(),
                        )
                      : null,
                ),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an email address.';
                  }
                  final emailRegex = RegExp(
                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Please enter a valid email address.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              if (!isLogin)
                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person),
                  ),
                  enableSuggestions: false,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty ||
                        value.trim().length < 4) {
                      return 'Please enter a valid username (at least 4 characters).';
                    }
                    return null;
                  },
                ),
              _PasswordField(
                passwordController: passwordController,
              ),
              const SizedBox(height: 20),
              if (isLoading) const CircularProgressIndicator(),
              if (!isLoading)
                ElevatedButton(
                  onPressed: onSubmit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: Text(isLogin ? 'Login' : 'Signup'),
                ),
              TextButton(
                onPressed: !isLoading ? onToggleAuthMode : null,
                child: Text(
                  isLogin ? 'Create new account' : 'I already have an account',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  final TextEditingController passwordController;

  const _PasswordField({
    required this.passwordController,
  });

  @override
  _PasswordFieldState createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.passwordController,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
      ),
      obscureText: !_isPasswordVisible,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a password.';
        }
        if (value.trim().length < 6) {
          return 'Password must be at least 6 characters long.';
        }
        return null;
      },
    );
  }
}
