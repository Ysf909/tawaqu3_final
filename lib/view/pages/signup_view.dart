import 'package:flutter/material.dart';
import 'login_view.dart';

class SignupView extends StatelessWidget {
  const SignupView({super.key});

  @override
  Widget build(BuildContext context) {
    // For simplicity, reuse the combined Auth screen
    return const LoginView();
  }
}


