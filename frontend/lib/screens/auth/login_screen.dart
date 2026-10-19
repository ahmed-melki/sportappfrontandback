import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/app_repositories.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/widgets.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'verify_email_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.repositories,
    required this.onAuthenticated,
    this.successMessage,
  });
  final AppRepositories repositories;
  final VoidCallback onAuthenticated;
  /// Optional message shown at the top (e.g. after successful password reset).
  final String? successMessage;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: 'lina.moreau@apex.app');
  final _password = TextEditingController(text: 'Password123!');
  bool _loading = false;
  String? _error;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _successMessage = widget.successMessage;
  }

  String? _validateEmail(String v) {
    if (v.isEmpty) return 'L\'email est requis.';
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!re.hasMatch(v)) return 'Format d\'email invalide.';
    return null;
  }

  Future<void> _login() async {
    final emailErr = _validateEmail(_email.text.trim());
    if (emailErr != null) {
      setState(() => _error = emailErr);
      return;
    }

    setState(() { _loading = true; _error = null; _successMessage = null; });
    try {
      final session = await widget.repositories.auth.login(_email.text.trim(), _password.text);
      if (!mounted) return;
      if (!session.emailVerified) {
        // Login succeeded but email not verified — push verification screen
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => VerifyEmailScreen(
              repositories: widget.repositories,
              email: _email.text.trim(),
              emailSent: true,
              onVerified: () {
                Navigator.of(context).pop();
                widget.onAuthenticated();
              },
            ),
          ),
        );
      } else {
        widget.onAuthenticated();
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToRegister() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => RegisterScreen(
          repositories: widget.repositories,
          onAuthenticated: widget.onAuthenticated,
        ),
      ),
    );
  }

  Future<void> _goToForgotPassword() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => ForgotPasswordScreen(repositories: widget.repositories),
      ),
    );
    if (result == 'success' && mounted) {
      setState(() => _successMessage = 'Mot de passe réinitialisé ! Tu peux te connecter.');
    }
  }

  @override
  void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.scaffold,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('APEX', style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Reprendre la cadence.', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.xl),
                  if (_successMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.volt.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.volt.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, color: AppColors.volt, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: TextStyle(color: AppColors.volt),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Mot de passe'),
                    onSubmitted: (_) => _loading ? null : _login(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _goToForgotPassword,
                      child: const Text('Mot de passe oublié ?'),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(_error!, style: const TextStyle(color: AppColors.coral)),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  ApexButton(
                    label: _loading ? 'Connexion…' : 'Se connecter',
                    icon: Icons.login_rounded,
                    onPressed: _loading ? null : _login,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ApexButton(
                    label: 'Créer un compte',
                    variant: ApexButtonVariant.ghost,
                    onPressed: _goToRegister,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
