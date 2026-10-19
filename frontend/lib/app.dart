import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/api/app_repositories.dart';
import 'core/app_scope.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/hub_screen.dart';
import 'screens/onboarding/onboarding_flow_screen.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

class ApexApp extends StatefulWidget {
  const ApexApp({super.key});

  @override
  State<ApexApp> createState() => _ApexAppState();
}

class _ApexAppState extends State<ApexApp> {
  late final AppRepositories _repositories;
  final _navigatorKey = GlobalKey<NavigatorState>();
  bool? _authenticated;
  bool _onboardingCompleted = true;
  bool _redirectingToLogin = false;
  bool _redirectingToVerify = false;

  @override
  void initState() {
    super.initState();
    _repositories = createRepositories(
      onUnauthorized: _goToLogin,
      onEmailNotVerified: _goToVerifyEmail,
    );
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final hasToken = await _repositories.auth.hasToken();
    if (!hasToken) {
      if (mounted) setState(() => _authenticated = false);
      return;
    }

    try {
      final bundle = await _repositories.profile.loadProfile();
      if (mounted) {
        setState(() {
          _authenticated = true;
          _onboardingCompleted = bundle.profile.onboardingCompleted;
        });
      }
    } catch (_) {
      // In case of error (e.g. offline/network), default to authenticated
      if (mounted) setState(() => _authenticated = true);
    }
  }

  Future<void> _authenticatedNow() async {
    _redirectingToLogin = false;
    _redirectingToVerify = false;

    // Check onboarding status
    try {
      final bundle = await _repositories.profile.loadProfile();
      if (!bundle.profile.onboardingCompleted) {
        if (mounted) {
          setState(() {
            _authenticated = true;
            _onboardingCompleted = false;
          });
        }
        _navigateTo(
          OnboardingFlowScreen(onFinished: _navigateToHub),
          'Onboarding',
        );
        return;
      }
    } catch (_) {
      // Fallback
    }

    if (mounted) {
      setState(() {
        _authenticated = true;
        _onboardingCompleted = true;
      });
    }
    _navigateToHub();
  }

  void _goToLogin() {
    if (_redirectingToLogin) return;
    _redirectingToLogin = true;
    _redirectingToVerify = false;
    if (mounted) setState(() => _authenticated = false);
    _navigateTo(
      LoginScreen(
        repositories: _repositories,
        onAuthenticated: _authenticatedNow,
      ),
      'Login',
    );
  }

  /// Called globally from ApiClient when a 403 email_not_verified response arrives.
  /// [email] is the email extracted from the failing request (may be empty).
  void _goToVerifyEmail(String email) {
    if (_redirectingToVerify) return;
    _redirectingToVerify = true;
    _repositories.client.resetEmailNotVerified();
    _navigateTo(
      VerifyEmailScreen(
        repositories: _repositories,
        email: email,
        emailSent: true,
        onVerified: _authenticatedNow,
      ),
      'VerifyEmail',
    );
  }

  void _onLogout() {
    _repositories.client.resetUnauthorized();
    _goToLogin();
  }

  void _navigateToHub() {
    _navigateTo(HubScreen(onLogout: _onLogout), 'Hub');
  }

  void _navigateTo(Widget screen, String destination) {
    final navigator = _navigatorKey.currentState;
    debugPrint('[Auth] navigation: $destination');
    if (navigator == null) {
      debugPrint('[Auth] navigation skipped: navigator key is not attached');
      return;
    }
    navigator.pushAndRemoveUntil<void>(
      MaterialPageRoute(builder: (_) => screen),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      repositories: _repositories,
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'APEX',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        builder: (context, child) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              systemNavigationBarColor: AppColors.scaffold,
              systemNavigationBarIconBrightness: Brightness.light,
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: _authenticated == null
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : _authenticated!
              ? (_onboardingCompleted
                  ? HubScreen(onLogout: _onLogout)
                  : OnboardingFlowScreen(onFinished: _navigateToHub))
              : LoginScreen(repositories: _repositories, onAuthenticated: _authenticatedNow),
      ),
    );
  }
}
