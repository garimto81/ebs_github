// Login screen — BS-01-auth login + 2FA + session restore.
//
// Ported from _archive-quasar/src/pages/LoginPage.vue (299 LOC).
// Flow:
//   1. Mount → tryRestoreSession (refresh-token cookie path)
//   2. Submit email/password → login()
//      - requires2fa → switch to TOTP step
//      - success → /series (or session restore dialog)
//   3. TOTP 6-digit → verify2fa()
//   4. Forgot Password link → /forgot-password

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../resources/l10n/app_localizations.dart';
import '../auth_provider.dart';

enum _LoginStep { credentials, totp }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _totpController = TextEditingController();

  var _step = _LoginStep.credentials;
  var _checking = true;
  var _submitting = false;
  var _showPassword = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tryRestore();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _totpController.dispose();
    super.dispose();
  }

  // -- Session restore on boot ------------------------------------------------

  Future<void> _tryRestore() async {
    try {
      final restored =
          await ref.read(authProvider.notifier).tryRestoreSession();
      if (restored && mounted) {
        _resolvePostLogin();
        return;
      }
    } catch (_) {
      // Fall through to login form.
    }
    if (mounted) setState(() => _checking = false);
  }

  void _resolvePostLogin() {
    // Navigate to the lobby dashboard after successful login.
    if (mounted) context.go('/lobby');
  }

  // -- Credential login -------------------------------------------------------

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final result = await ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
      if (!mounted) return;
      if (result.success) {
        _resolvePostLogin();
        return;
      }
      if (result.requires2fa) {
        setState(() => _step = _LoginStep.totp);
        return;
      }
      setState(() => _errorMessage = result.errorMessage ?? 'Login failed');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // -- 2FA verification -------------------------------------------------------

  Future<void> _handleVerify2fa() async {
    final code = _totpController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _errorMessage =
          AppLocalizations.of(context)?.loginErrorsTwoFactorInvalid ??
              'Invalid code');
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final result = await ref.read(authProvider.notifier).verify2fa(code);
      if (!mounted) return;
      if (result.success) {
        _resolvePostLogin();
        return;
      }
      setState(() =>
          _errorMessage = result.errorMessage ?? '2FA verification failed');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _backToCredentials() {
    setState(() {
      _step = _LoginStep.credentials;
      _totpController.clear();
      _errorMessage = null;
    });
  }

  // -- Build ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Text(l.loginTitle,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(l.loginSubtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline)),
                  const SizedBox(height: 24),

                  // Step content
                  if (_step == _LoginStep.credentials)
                    _buildCredentialsForm(l, theme)
                  else
                    _buildTotpForm(l, theme),
                ],
              ),
            ),
          ),
        ),
      ),

      // Session restore dialog (shown as an overlay when needed).
    );
  }

  Widget _buildCredentialsForm(AppLocalizations l, ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(labelText: l.loginEmail),
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            validator: (v) =>
                (v == null || v.isEmpty) ? l.commonRequired : null,
          ),
          const SizedBox(height: 12),

          // Password
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: l.loginPassword,
              suffixIcon: IconButton(
                icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () =>
                    setState(() => _showPassword = !_showPassword),
              ),
            ),
            obscureText: !_showPassword,
            validator: (v) =>
                (v == null || v.isEmpty) ? l.commonRequired : null,
          ),
          const SizedBox(height: 8),

          // Error banner
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: theme.colorScheme.onErrorContainer,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Submit
          FilledButton(
            onPressed: _submitting ? null : _handleLogin,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l.loginSubmit),
          ),
          const SizedBox(height: 16),

          // Divider
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(l.loginOr,
                    style: TextStyle(color: theme.colorScheme.outline)),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),

          // Google login
          OutlinedButton.icon(
            onPressed: () {
              // Google OAuth redirect — web-only.
              // TODO: wire getGoogleLoginUrl() when web OAuth is available.
            },
            icon: const Icon(Icons.login),
            label: Text(l.loginGoogleLogin),
          ),
          const SizedBox(height: 8),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.go('/forgot-password'),
              child: Text(l.loginForgotPassword),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotpForm(AppLocalizations l, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.loginTwoFactorPrompt, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 12),

        // 6-digit code
        TextFormField(
          controller: _totpController,
          decoration: InputDecoration(labelText: l.loginTwoFactor),
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 8),
          autofocus: true,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 8),

        // Error banner
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: theme.colorScheme.onErrorContainer,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Verify
        FilledButton(
          onPressed: _submitting ? null : _handleVerify2fa,
          child: _submitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l.loginVerify),
        ),
        const SizedBox(height: 8),

        // Back
        TextButton(
          onPressed: _backToCredentials,
          child: Text(l.commonBack),
        ),
      ],
    );
  }
}
