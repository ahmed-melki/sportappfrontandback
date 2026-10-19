import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api/api_client.dart';
import '../../core/api/app_repositories.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/widgets.dart';

/// Screen shown after register or when a 403 email_not_verified is caught globally.
/// [onVerified] is called when the code is accepted — caller should navigate to onboarding/hub.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.repositories,
    required this.email,
    required this.emailSent,
    required this.onVerified,
  });

  final AppRepositories repositories;
  final String email;
  /// Whether the backend already sent the email. If false we show a warning first.
  final bool emailSent;
  final VoidCallback onVerified;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  String? _error;
  String? _successMessage;

  // 60 s countdown for resend button
  int _countdown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.emailSent) {
      _startCountdown();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _countdown--;
        if (_countdown <= 0) t.cancel();
      });
    });
  }

  String? _validateCode(String code) {
    if (code.isEmpty) return 'Le code est requis.';
    if (code.length != 6 || int.tryParse(code) == null) return 'Le code doit être 6 chiffres.';
    return null;
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    final err = _validateCode(code);
    if (err != null) { setState(() => _error = err); return; }

    setState(() { _loading = true; _error = null; _successMessage = null; });
    try {
      await widget.repositories.auth.verifyEmail(email: widget.email, code: code);
      if (mounted) widget.onVerified();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = _friendlyCodeError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() { _resending = true; _error = null; _successMessage = null; });
    try {
      await widget.repositories.auth.resendCode(widget.email);
      if (mounted) {
        setState(() => _successMessage = 'Un nouveau code a été envoyé.');
        _startCountdown();
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = _friendlyCodeError(e));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  String _friendlyCodeError(ApiException e) {
    if (e.statusCode == 429) return 'Trop de tentatives. Réessaie dans quelques minutes.';
    if (e.message.toLowerCase().contains('invalid') || e.message.toLowerCase().contains('incorrect')) {
      return 'Code incorrect ou expiré.';
    }
    return e.message;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final canResend = _countdown == 0 && !_resending;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Vérification email')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.volt.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.volt.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mark_email_unread_outlined, color: AppColors.volt, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Vérifie ton email', style: text.titleMedium?.copyWith(color: AppColors.volt)),
                          const SizedBox(height: 4),
                          Text(
                            widget.emailSent
                              ? 'Un code à 6 chiffres a été envoyé à\n${widget.email}'
                              : 'L\'envoi de l\'email a échoué. Utilise le bouton Renvoyer ci-dessous.',
                            style: text.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Code de vérification', style: text.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: text.headlineMedium?.copyWith(letterSpacing: 8),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: '• • • • • •',
                  counterText: '',
                ),
                onSubmitted: (_) => _loading ? null : _verify(),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_error!, style: const TextStyle(color: AppColors.coral)),
              ],
              if (_successMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_successMessage!, style: TextStyle(color: AppColors.volt)),
              ],
              const SizedBox(height: AppSpacing.lg),
              ApexButton(
                label: _loading ? 'Vérification…' : 'Vérifier',
                icon: Icons.check_circle_outline_rounded,
                onPressed: _loading ? null : _verify,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    canResend
                        ? 'Tu n\'as pas reçu le code ? '
                        : 'Renvoyer dans ${_countdown}s — ',
                    style: text.bodySmall,
                  ),
                  if (canResend)
                    TextButton(
                      onPressed: _resending ? null : _resend,
                      child: Text(_resending ? 'Envoi…' : 'Renvoyer le code'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
