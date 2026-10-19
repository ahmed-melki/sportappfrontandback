import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/app_scope.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/widgets.dart';

/// Screen accessible from the Profile module to change the logged-in user's password.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _newPwd = TextEditingController();
  final _confirmation = TextEditingController();
  bool _loading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirmation = true;
  String? _error;
  String? _success;
  final Map<String, List<String>> _fieldErrors = {};

  String? _validateCurrent(String v) => v.isEmpty ? 'Le mot de passe actuel est requis.' : null;
  String? _validateNew(String v) {
    if (v.isEmpty) return 'Le nouveau mot de passe est requis.';
    if (v.length < 8) return 'Au moins 8 caractères.';
    return null;
  }
  String? _validateConfirmation(String v) => v != _newPwd.text ? 'Les mots de passe ne correspondent pas.' : null;

  String? _firstError() =>
      _validateCurrent(_current.text) ??
      _validateNew(_newPwd.text) ??
      _validateConfirmation(_confirmation.text);

  Future<void> _submit() async {
    setState(() { _fieldErrors.clear(); _error = null; _success = null; });
    final localErr = _firstError();
    if (localErr != null) { setState(() => _error = localErr); return; }

    setState(() => _loading = true);
    try {
      await AppScope.of(context).auth.changePassword(
        currentPassword: _current.text,
        password: _newPwd.text,
        passwordConfirmation: _confirmation.text,
      );
      if (!mounted) return;
      setState(() {
        _success = 'Mot de passe modifié avec succès.';
        _current.clear();
        _newPwd.clear();
        _confirmation.clear();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _fieldErrors.addAll(e.fieldErrors);
        _error = e.fieldErrors.values.expand((v) => v).firstOrNull ?? e.message;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _current.dispose();
    _newPwd.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Changer le mot de passe')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              Text('Sécurité', style: text.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text('Le nouveau mot de passe doit faire au moins 8 caractères.', style: text.bodySmall),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _current,
                obscureText: _obscureCurrent,
                decoration: InputDecoration(
                  labelText: 'Mot de passe actuel',
                  errorText: _fieldErrors['currentPassword']?.firstOrNull,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _newPwd,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  errorText: _fieldErrors['password']?.firstOrNull,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _confirmation,
                obscureText: _obscureConfirmation,
                decoration: InputDecoration(
                  labelText: 'Confirmer le nouveau mot de passe',
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
              if (_success != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_success!, style: TextStyle(color: AppColors.volt)),
              ],
              const SizedBox(height: AppSpacing.lg),
              ApexButton(
                label: _loading ? 'Modification…' : 'Changer le mot de passe',
                icon: Icons.lock_outline_rounded,
                onPressed: _loading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
