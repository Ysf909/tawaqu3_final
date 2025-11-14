import 'package:flutter/material.dart';
import 'package:tawaqu3_final/view/widgets/card_container.dart';
import 'package:tawaqu3_final/view/widgets/input_field.dart';
import 'package:tawaqu3_final/view/widgets/primary_button.dart';
import '../../core/router/app_router.dart';

class SignupView extends StatelessWidget {
  const SignupView({super.key});

  @override
  Widget build(BuildContext context) {
    final signup = CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Create Account',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InputField(
                  controller: TextEditingController(),
                  label: 'First Name',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InputField(
                  controller: TextEditingController(),
                  label: 'Last Name',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InputField(
            controller: TextEditingController(),
            label: 'Email',
          ),
          const SizedBox(height: 12),
          InputField(
            controller: TextEditingController(),
            label: 'Password',
            obscure: true,
          ),
          const SizedBox(height: 12),
          InputField(
            controller: TextEditingController(),
            label: 'Confirm Password',
            obscure: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                value: true,
                onChanged: (v) {},
              ),
              const Expanded(
                child: Text('I agree to Terms & Privacy Policy'),
              ),
            ],
          ),
          PrimaryButton(
            label: 'SIGN UP',
            onPressed: () => Navigator.pushReplacementNamed(
              context,
              AppRouter.MainPageRoute,
            ),
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
              const Text('Already have an account? '),
              InkWell(
                onTap: () =>
                    Navigator.pushNamed(context, AppRouter.authRoute),
                child: const Text(
                  'Log In',
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
      appBar: AppBar(title: const Text('Sign Up')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;

          if (isWide) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: signup,
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: signup,
          );
        },
      ),
    );
  }
}
