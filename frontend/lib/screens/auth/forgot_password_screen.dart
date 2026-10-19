import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/app_repositories.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/widgets.dart';
import 'reset_password_screen.dart';

/// Screen 1 of the forgot-password flow: enter email → POST /auth/forgot-password.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.repositories});
  final AppRepositories repositories;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _loading = false;
  String? _error;
  final Map<String, List<String>> _fieldErrors = {};

  String? _validateEmail(String v) {
    if (v.isEmpty) return 'L\'email est requis.';
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!re.hasMatch(v)) return 'Format d\'email invalide.';
    return null;
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final err = _validateEmail(email);
    if (err != null) { setState(() => _error = err); return; }

    setState(() { _loading = true; _error = null; _fieldErrors.clear(); });
    try {
      await widget.repositories.auth.forgotPassword(email);
      if (!mounted) return;
      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute<String>(
          builder: (_) => ResetPasswordScreen(repositories: widget.repositories, email: email),
        ),
      );
      if (result == 'success' && mounted) {
        // Pop ForgotPasswordScreen and pass 'success' up to LoginScreen
        Navigator.of(context).pop('success');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _fieldErrors.addAll(e.fieldErrors);
        _error = e.fieldErrors['email']?.firstOrNull ?? e.message;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() { _email.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              Text('Réinitialisation', style: text.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Saisis ton adresse email. On t\'envoie un code à 6 chiffres.',
                style: text.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  errorText: _fieldErrors['email']?.firstOrNull,
                ),
                onSubmitted: (_) => _loading ? null : _submit(),
              ),
              if (_error != null && _fieldErrors['email'] == null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_error!, style: const TextStyle(color: AppColors.coral)),
              ],
              const SizedBox(height: AppSpacing.lg),
              ApexButton(
                label: _loading ? 'Envoi…' : 'Envoyer le code',
                icon: Icons.send_rounded,
                onPressed: _loading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
