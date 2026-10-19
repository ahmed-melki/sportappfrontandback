import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/app_repositories.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/widgets.dart';
import 'verify_email_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.repositories, required this.onAuthenticated});
  final AppRepositories repositories;
  final VoidCallback onAuthenticated;
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _loading = false;
  String? _error;
  final Map<String, List<String>> _fieldErrors = {};

  String? _validateEmail(String v) {
    if (v.isEmpty) return 'L\'email est requis.';
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!re.hasMatch(v)) return 'Format d\'email invalide.';
    return null;
  }

  String? _validatePassword(String v) {
    if (v.isEmpty) return 'Le mot de passe est requis.';
    if (v.length < 8) return 'Au moins 8 caractères.';
    return null;
  }

  String? _validateConfirmation(String v) =>
      v != _password.text ? 'Les mots de passe ne correspondent pas.' : null;

  Future<void> _register() async {
    setState(() { _fieldErrors.clear(); _error = null; });

    // Local validation
    final emailErr = _validateEmail(_email.text.trim());
    if (emailErr != null) { setState(() => _error = emailErr); return; }
    final pwdErr = _validatePassword(_password.text);
    if (pwdErr != null) { setState(() => _error = pwdErr); return; }
    final confErr = _validateConfirmation(_confirmation.text);
    if (confErr != null) { setState(() => _error = confErr); return; }

    setState(() => _loading = true);
    try {
      final session = await widget.repositories.auth.register(
        firstName: _first.text.trim(),
        lastName: _last.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        passwordConfirmation: _confirmation.text,
      );
      if (!mounted) return;

      if (session.emailVerified) {
        // Edge case: already verified (unlikely on register, but handle it)
        widget.onAuthenticated();
        return;
      }

      // Navigate to email verification screen
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => VerifyEmailScreen(
            repositories: widget.repositories,
            email: _email.text.trim(),
            emailSent: session.emailSent,
            onVerified: () {
              // Pop VerifyEmailScreen, then pop RegisterScreen
              Navigator.of(context)
                ..pop() // pop verify screen
                ..pop(); // pop register screen
              widget.onAuthenticated();
            },
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      final combined = error.fieldErrors.values.expand((items) => items).join('\n');
      setState(() {
        _fieldErrors.addAll(error.fieldErrors);
        _error = combined.isNotEmpty ? combined : error.message;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final c in [_first, _last, _email, _password, _confirmation]) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(title: const Text('Créer un compte')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            child: Column(
              children: [
                TextField(
                  controller: _first,
                  decoration: InputDecoration(
                    labelText: 'Prénom',
                    errorText: _fieldErrors['firstName']?.firstOrNull,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _last,
                  decoration: InputDecoration(
                    labelText: 'Nom',
                    errorText: _fieldErrors['lastName']?.firstOrNull,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    errorText: _fieldErrors['email']?.firstOrNull,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    errorText: _fieldErrors['password']?.firstOrNull,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _confirmation,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    errorText: _fieldErrors['passwordConfirmation']?.firstOrNull,
                  ),
                ),
                if (_error != null && _fieldErrors.isEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(_error!, style: const TextStyle(color: AppColors.coral)),
                ],
                const SizedBox(height: AppSpacing.lg),
                ApexButton(
                  label: _loading ? 'Création…' : 'Créer mon compte',
                  onPressed: _loading ? null : _register,
                ),
              ],
            ),
          ),
        ),
      );
}
