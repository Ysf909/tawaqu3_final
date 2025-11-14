import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tawaqu3_final/view/widgets/card_container.dart';
import 'package:tawaqu3_final/view/widgets/input_field.dart';
import 'package:tawaqu3_final/view/widgets/primary_button.dart';
import '../../core/router/app_router.dart';

import '../../view_model/auth_view_model.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    final login = CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tawaqu3',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          InputField(controller: _email, label: 'Email'),
          const SizedBox(height: 12),
          InputField(
            controller: _password,
            label: 'Password',
            obscure: true,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Text('Forgot Password?'),
            ),
          ),
          const SizedBox(height: 8),
          PrimaryButton(
            label: 'LOG IN',
            loading: vm.isLoading,
            onPressed: () async {
              final ok = await vm.login(_email.text, _password.text);
              if (ok && mounted) {
                Navigator.pushReplacementNamed(
                  context,
                  AppRouter.MainPageRoute,
                );
              }
            },
          ),
          const SizedBox(height: 12),
          const Divider(),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.g_mobiledata),
            label: const Text('Continue with Google'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.apple),
            label: const Text('Continue with Apple'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.facebook),
            label: const Text('Continue with Facebook'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Don't have an account? "),
              InkWell(
                onTap: () =>
                    Navigator.pushNamed(context, AppRouter.signupRoute),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Authentication')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;

          if (isWide) {
            /// Center the same card on big screens
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: login,
              ),
            );
          }

          /// On small screens: scrollable single card
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: login,
          );
        },
      ),
    );
  }
} 


