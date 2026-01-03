import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tawaqu3_final/validation.dart';
import 'package:tawaqu3_final/view/widgets/card_container.dart';
import 'package:tawaqu3_final/view/widgets/input_field.dart';
import 'package:tawaqu3_final/view/widgets/primary_button.dart';

import '../../core/router/app_router.dart';
import '../../view_model/signup_view_model.dart';

class SignupView extends StatelessWidget {
  const SignupView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SignupViewModel(),
      child: const _SignupViewBody(),
    );
  }
}

class _SignupViewBody extends StatefulWidget {
  const _SignupViewBody();

  @override
  State<_SignupViewBody> createState() => _SignupViewBodyState();
}

class _SignupViewBodyState extends State<_SignupViewBody> {
  final _formKey = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _agreeToTerms = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignupViewModel>();

    final signupCard = Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: CardContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create Account',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: InputField(
                    controller: _firstName,
                    label: 'First Name',
                    validator: (v) => Validation.name(v, 'First name'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InputField(
                    controller: _lastName,
                    label: 'Last Name',
                    validator: (v) => Validation.name(v, 'Last name'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            InputField(
              controller: _email,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: (v) => Validation.email(v),
            ),
            const SizedBox(height: 12),

            InputField(
              controller: _password,
              label: 'Password',
              obscure: true,
              validator: (v) => Validation.password(v, _password.text),
            ),
            const SizedBox(height: 12),

            InputField(
              controller: _confirmPassword,
              label: 'Confirm Password',
              obscure: true,
              validator: (v) => Validation.confirmPassword(v, _password.text),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Checkbox(
                  value: _agreeToTerms,
                  onChanged: (v) {
                    setState(() {
                      _agreeToTerms = v ?? false;
                    });
                  },
                ),
                const Expanded(
                  child: Text('I agree to Terms & Privacy Policy'),
                ),
              ],
            ),

            PrimaryButton(
              label: 'SIGN UP',
              loading: vm.isLoading,
              onPressed: () async {
                if (!_agreeToTerms) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'You must agree to the Terms & Privacy Policy.',
                      ),
                    ),
                  );
                  return;
                }

                if (!_formKey.currentState!.validate()) return;

                // sync controllers into ViewModel model
                vm.updateFirstName(_firstName.text.trim());
                vm.updateLastName(_lastName.text.trim());
                vm.updateEmail(_email.text.trim());
                vm.updatePassword(_password.text);

                final status = await vm.signup();

                if (!mounted) return;

                switch (status) {
                  case SignupStatus.success:
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Account created successfully. You can now log in.',
                        ),
                      ),
                    );
                    Navigator.pushReplacementNamed(
                      context,
                      AppRouter.authRoute,
                    );
                    break;

                  case SignupStatus.emailAlreadyExists:
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'An account with this email already exists.',
                        ),
                      ),
                    );
                    break;

                  case SignupStatus.error:
                  default:
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'An error occurred while signing up. Please try again later.',
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
                // TODO: Supabase OAuth if needed
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
                const Text('Already have an account? '),
                InkWell(
                  onTap: () =>
                      Navigator.pushNamed(context, AppRouter.authRoute),
                  child: const Text(
                    'Log In',
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ],
        ),
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
                child: signupCard,
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: signupCard,
          );
        },
      ),
    );
  }
}
