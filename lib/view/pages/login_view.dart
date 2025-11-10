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

    return Scaffold(
      appBar: AppBar(title: const Text('Authentication')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          final login = CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Tawaqu3', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                InputField(controller: _email, label: 'Email'),
                const SizedBox(height: 12),
                InputField(controller: _password, label: 'Password', obscure: true),
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: TextButton(onPressed: (){}, child: const Text('Forgot Password?'))),
                const SizedBox(height: 8),
                PrimaryButton(label: 'LOG IN', loading: vm.isLoading, onPressed: () async {
                  final ok = await vm.login(_email.text, _password.text);
                  if (ok && mounted) Navigator.pushReplacementNamed(context, AppRouter.dashboardRoute);
                }),
                const SizedBox(height: 12),
                const Divider(),
                OutlinedButton.icon(onPressed: (){}, icon: const Icon(Icons.g_mobiledata), label: const Text('Continue with Google')),
                const SizedBox(height: 8),
                OutlinedButton.icon(onPressed: (){}, icon: const Icon(Icons.apple), label: const Text('Continue with Apple')),
                const SizedBox(height: 8),
                OutlinedButton.icon(onPressed: (){}, icon: const Icon(Icons.facebook), label: const Text('Continue with Facebook')),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    InkWell(
                      onTap: () => Navigator.pushNamed(context, AppRouter.signupRoute),
                      child: const Text('Sign Up', style: TextStyle(decoration: TextDecoration.underline)),
                    )
                  ],
                )
              ],
            ),
          );

          final signupPanel = CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Create Account', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: InputField(controller: TextEditingController(), label: 'First Name')),
                  const SizedBox(width: 12),
                  Expanded(child: InputField(controller: TextEditingController(), label: 'Last Name')),
                ]),
                const SizedBox(height: 12),
                InputField(controller: TextEditingController(), label: 'Email'),
                const SizedBox(height: 12),
                InputField(controller: TextEditingController(), label: 'Password', obscure: true),
                const SizedBox(height: 12),
                InputField(controller: TextEditingController(), label: 'Confirm Password', obscure: true),
                const SizedBox(height: 12),
                Row(children: [
                  Checkbox(value: true, onChanged: (v){}),
                  const Expanded(child: Text('I agree to Terms & Privacy Policy')),
                ]),
                PrimaryButton(label: 'SIGN UP', onPressed: () => Navigator.pushReplacementNamed(context, AppRouter.dashboardRoute)),
                const SizedBox(height: 12),
                const Divider(),
                OutlinedButton.icon(onPressed: (){}, icon: const Icon(Icons.g_mobiledata), label: const Text('Continue with Google')),
                const SizedBox(height: 8),
                OutlinedButton.icon(onPressed: (){}, icon: const Icon(Icons.apple), label: const Text('Continue with Apple')),
                const SizedBox(height: 8),
                OutlinedButton.icon(onPressed: (){}, icon: const Icon(Icons.facebook), label: const Text('Continue with Facebook')),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('Already have an account? '),
                  InkWell(onTap: () => Navigator.pushNamed(context, AppRouter.authRoute), child: const Text('Log In', style: TextStyle(decoration: TextDecoration.underline))),
                ]),
              ],
            ),
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: login),
                Expanded(child: signupPanel),
              ],
            );
          }
          return SingleChildScrollView(child: Column(children: [login, signupPanel]));
        },
      ),
    );
  }
}


