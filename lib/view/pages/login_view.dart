import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tawaqu3_final/services/social_auth_service.dart';
import 'package:tawaqu3_final/services/user_service.dart';
import 'package:tawaqu3_final/validation.dart';
import 'package:tawaqu3_final/view/widgets/card_container.dart';
import 'package:tawaqu3_final/view/widgets/input_field.dart';
import 'package:tawaqu3_final/view/widgets/primary_button.dart';
import 'package:tawaqu3_final/view/widgets/responsive_form_container.dart';
import 'package:tawaqu3_final/view_model/user_session_view_model.dart';

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
  final socialAuth = SocialAuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final userService = UserService();

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
            ),
            const SizedBox(height: 12),

            // Password
            InputField(
              controller: _password,
              label: 'Password',
              obscure: true,
              // password() only takes one argument
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

            // LOGIN BUTTON
            PrimaryButton(
              label: 'LOG IN',
              loading: vm.isLoading,
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;

                final email = _email.text.trim();
                final password = _password.text;

                debugPrint('Login button pressed with: $email / $password');

                final status = await vm.login(email, password);

                if (!mounted) return;

                switch (status) {
                  case LoginStatus.success:
                   final appUser = vm.loggedInUser;

                    if (appUser != null) {
                      // Store it globally so MenuView & others can show the name
                      context.read<UserSessionViewModel>().setUser(appUser);
                    } else {
                      debugPrint('LoginStatus.success but vm.loggedInUser is null 🤔');
                    }
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
                    break;

                  case LoginStatus.wrongPassword:
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Wrong email or password.'),
                      ),
                    );
                    break;

                  case LoginStatus.emailNotConfirmed:
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Your email is not confirmed. Please check your inbox and verify your email.',
                        ),
                      ),
                    );
                    break;

                  case LoginStatus.error:
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'An error occurred while logging in. Please try again later.',
                        ),
                      ),
                    );
                    break;
                }
              },
            ),

            const SizedBox(height: 12),
            const Divider(),

            OutlinedButton.icon(
  onPressed: () async {
    try {
      final res = await socialAuth.signInWithGoogle();
if (res?.session == null) return; // cancelled

final userRow = await userService.ensureUserRow(provider: 'google');
context.read<UserSessionViewModel>().setUser(userRow); // or AppUser.fromMap(userRow)
Navigator.pushReplacementNamed(context, AppRouter.MainPageRoute); // cancelled

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRouter.MainPageRoute);
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google sign-in failed.')),
      );
    }
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
  onPressed: () async {
    try {
      final res = await socialAuth.signInWithFacebook();
if (res?.session == null) return;

final userRow = await userService.ensureUserRow(provider: 'facebook');
context.read<UserSessionViewModel>().setUser(userRow);
Navigator.pushReplacementNamed(context, AppRouter.MainPageRoute);
 // cancelled

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRouter.MainPageRoute);
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Facebook sign-in failed.')),
      );
    }
  },
  icon: const Icon(Icons.facebook),
  label: const Text('Continue with Facebook'),
),
            const SizedBox(height: 16),

            // Resend verification email
            TextButton(
              onPressed: () async {
                final email = _email.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Enter your email first to resend verification.',
                      ),
                    ),
                  );
                  return;
                }

                final client = Supabase.instance.client;
                try {
                  await client.auth.resend(
                    type: OtpType.signup,
                    email: email,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Verification email sent. Please check your inbox.',
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Could not resend verification email.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Resend verification email'),
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
      appBar: AppBar(title: const Text('Tawaqu3')),
      body: ResponsiveFormContainer(
        maxWidth: BouncingScrollSimulation.maxSpringTransferVelocity,
        child: loginCard,
        
      ),
    );
  }
}
