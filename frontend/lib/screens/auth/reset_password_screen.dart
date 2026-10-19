import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api/api_client.dart';
import '../../core/api/app_repositories.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/widgets.dart';

/// Screen 2 of the forgot-password flow: enter code + new password → POST /auth/reset-password.
/// On success pops back to Login with a success message.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.repositories, required this.email});
  final AppRepositories repositories;
  final String email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  String? _error;
  final Map<String, List<String>> _fieldErrors = {};

  String? _validateCode(String v) {
    if (v.isEmpty) return 'Le code est requis.';
    if (v.length != 6 || int.tryParse(v) == null) return 'Le code doit être 6 chiffres.';
    return null;
  }

  String? _validatePassword(String v) {
    if (v.isEmpty) return 'Le mot de passe est requis.';
    if (v.length < 8) return 'Au moins 8 caractères.';
    return null;
  }

  String? _validateConfirmation(String v) {
    if (v != _password.text) return 'Les mots de passe ne correspondent pas.';
    return null;
  }

  String? _firstError() {
    return _validateCode(_code.text.trim()) ??
        _validatePassword(_password.text) ??
        _validateConfirmation(_confirmation.text);
  }

  Future<void> _submit() async {
    setState(() { _fieldErrors.clear(); _error = null; });
    final localErr = _firstError();
    if (localErr != null) { setState(() => _error = localErr); return; }

    setState(() => _loading = true);
    try {
      await widget.repositories.auth.resetPassword(
        email: widget.email,
        code: _code.text.trim(),
        password: _password.text,
        passwordConfirmation: _confirmation.text,
      );
      if (!mounted) return;
      // Pop all the way back to Login (pushReplacement twice was done on step 1)
      Navigator.of(context).pop('success');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _fieldErrors.addAll(e.fieldErrors);
        if (e.statusCode == 429) {
          _error = 'Trop de tentatives. Réessaie dans quelques minutes.';
        } else {
          _error = _friendlyCodeError(e);
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyCodeError(ApiException e) {
    if (e.message.toLowerCase().contains('invalid') || e.message.toLowerCase().contains('incorrect')) {
      return 'Code incorrect ou expiré.';
    }
    return e.message;
  }

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Nouveau mot de passe')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              Text('Code envoyé à', style: text.bodySmall),
              const SizedBox(height: 2),
              Text(widget.email, style: text.titleSmall?.copyWith(color: AppColors.volt)),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: text.headlineSmall?.copyWith(letterSpacing: 6),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'Code à 6 chiffres',
                  hintText: '• • • • • •',
                  counterText: '',
                  errorText: _fieldErrors['code']?.firstOrNull,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _password,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  errorText: _fieldErrors['password']?.firstOrNull,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _confirmation,
                obscureText: _obscureConfirmation,
                decoration: InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  errorText: _fieldErrors['passwordConfirmation']?.firstOrNull,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmation ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscureConfirmation = !_obscureConfirmation),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_error!, style: const TextStyle(color: AppColors.coral)),
              ],
              const SizedBox(height: AppSpacing.lg),
              ApexButton(
                label: _loading ? 'Réinitialisation…' : 'Réinitialiser le mot de passe',
                icon: Icons.lock_reset_rounded,
                onPressed: _loading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
