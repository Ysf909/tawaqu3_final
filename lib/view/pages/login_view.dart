import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tawaqu3_final/validation.dart';
import 'package:tawaqu3_final/view/widgets/card_container.dart';
import 'package:tawaqu3_final/view/widgets/input_field.dart';
import 'package:tawaqu3_final/view/widgets/primary_button.dart';
import 'package:tawaqu3_final/view/widgets/responsive_form_container.dart';

import '../../core/router/app_router.dart';
import '../../view_model/login_view_model.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginViewModel(),
      child: const _LoginViewBody(),
    );
  }
}

class _LoginViewBody extends StatefulWidget {
  const _LoginViewBody();

  @override
  State<_LoginViewBody> createState() => _LoginViewBodyState();
}

class _LoginViewBodyState extends State<_LoginViewBody> {
  final _formKey = GlobalKey<FormState>();

  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginViewModel>();

    final loginCard = Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: CardContainer(
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

            // Email
            InputField(
              controller: _email,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: Validation.email,
              // keep ViewModel in sync (optional but MVVM-ish)
              // onChanged is assumed – if your InputField doesn't have it, you can
              // just call vm.updateEmail in onChanged of TextFormField there.
            ),
            const SizedBox(height: 12),

            // Password
            InputField(
              controller: _password,
              label: 'Password',
              obscure: true,
              validator: (value) => Validation.password(value, _password.text),
            ),
            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // TODO: forgot password with Supabase resetPasswordForEmail
                },
                child: const Text('Forgot Password?'),
              ),
            ),
            const SizedBox(height: 8),

            PrimaryButton(
              label: 'LOG IN',
              loading: vm.isLoading,
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;

                // sync controllers into the ViewModel model
                vm.updateEmail(_email.text.trim());
                vm.updatePassword(_password.text);

                final status = await vm.login();

                if (!mounted) return;

                switch (status) {
                  case LoginStatus.success:
                    Navigator.pushReplacementNamed(
                      context,
                      AppRouter.MainPageRoute,
                    );
                    break;

                  case LoginStatus.userNotFound:
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'No account found with this email. Please sign up first.',
                        ),
                      ),
                    );
                    Navigator.pushNamed(context, AppRouter.signupRoute);
                    break;

                  case LoginStatus.wrongPassword:
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Wrong email or password.'),
                      ),
                    );
                    break;

                  case LoginStatus.error:
                  default:
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'An error occurred while logging in. Please try again later.',
                        ),
                      ),
                    );
                }
              },
            ),

            const SizedBox(height: 12),
            const Divider(),

            OutlinedButton.icon(
              onPressed: () {
                // TODO: OAuth via Supabase if you want
              },
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
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Authentication')),
      body: ResponsiveFormContainer(
        child: loginCard,
      ),
    );
  }
}
