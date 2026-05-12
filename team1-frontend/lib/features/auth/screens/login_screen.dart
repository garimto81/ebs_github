// Login screen — BS-01-auth login + 2FA + session restore.
//
// 2026-05-12 cycle 11 — mockup HTML 정합 재설계.
// SSOT: docs/mockups/ebs-lobby-00-login.html
// Layout: dark `EBS` header bar + centered white login-box (340px) +
//         email/password rows + Forgot link + black `Login` button +
//         outlined `Sign In With Entra ID (TBD)` button.
//
// Flow (unchanged from prior implementation):
//   1. Mount → tryRestoreSession (refresh-token cookie path)
//   2. Submit email/password → login()
//      - requires2fa → switch to TOTP step
//      - success → /lobby
//   3. TOTP 6-digit → verify2fa()
//   4. Forgot Password link → /forgot-password

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../foundation/theme/lobby_mockup_tokens.dart';
import '../../../foundation/widgets/build_id_label.dart';
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
    if (mounted) context.go('/lobby');
  }

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

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: LobbyMockupTokens.bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: LobbyMockupTokens.bg,
      body: Stack(
        children: [
          Column(
            children: [
              // ── Dark header (logo only — mockup 00-login.html) ──
              Container(
                height: 32,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                color: LobbyMockupTokens.headerBg,
                alignment: Alignment.centerLeft,
                child: const Text(
                  'EBS',
                  style: TextStyle(
                    color: LobbyMockupTokens.headerInk,
                    fontSize: LobbyMockupTokens.fsHeaderLogo,
                    fontWeight: FontWeight.w700,
                    letterSpacing: LobbyMockupTokens.letterSpacingHeader,
                  ),
                ),
              ),

              // ── Centered login box ──
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: _LoginBox(
                        step: _step,
                        formKey: _formKey,
                        emailController: _emailController,
                        passwordController: _passwordController,
                        totpController: _totpController,
                        submitting: _submitting,
                        errorMessage: _errorMessage,
                        onLogin: _handleLogin,
                        onVerify: _handleVerify2fa,
                        onBack: _backToCredentials,
                        onForgot: () => context.go('/forgot-password'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 2026-05-07: 빌드 식별 표시 — SW 캐시 vs 새 빌드 혼동 차단.
          const Positioned(
            right: 16,
            bottom: 12,
            child: BuildIdLabel(),
          ),
        ],
      ),
    );
  }
}

class _LoginBox extends StatelessWidget {
  const _LoginBox({
    required this.step,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.totpController,
    required this.submitting,
    required this.errorMessage,
    required this.onLogin,
    required this.onVerify,
    required this.onBack,
    required this.onForgot,
  });

  final _LoginStep step;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController totpController;
  final bool submitting;
  final String? errorMessage;
  final VoidCallback onLogin;
  final VoidCallback onVerify;
  final VoidCallback onBack;
  final VoidCallback onForgot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      decoration: BoxDecoration(
        color: LobbyMockupTokens.bg,
        border: Border.all(color: LobbyMockupTokens.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title — mockup `.login-title { font-size: 18px; font-weight: 700 }`
          const Text(
            'Login',
            style: TextStyle(
              fontSize: LobbyMockupTokens.fsTitle,
              fontWeight: FontWeight.w700,
              color: LobbyMockupTokens.ink,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),

          if (step == _LoginStep.credentials)
            _CredentialsForm(
              formKey: formKey,
              emailController: emailController,
              passwordController: passwordController,
              submitting: submitting,
              errorMessage: errorMessage,
              onLogin: onLogin,
              onForgot: onForgot,
            )
          else
            _TotpForm(
              totpController: totpController,
              submitting: submitting,
              errorMessage: errorMessage,
              onVerify: onVerify,
              onBack: onBack,
            ),
        ],
      ),
    );
  }
}

class _CredentialsForm extends StatelessWidget {
  const _CredentialsForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.submitting,
    required this.errorMessage,
    required this.onLogin,
    required this.onForgot,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool submitting;
  final String? errorMessage;
  final VoidCallback onLogin;
  final VoidCallback onForgot;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MockupTextField(
            controller: emailController,
            icon: Icons.person_outline,
            hint: 'Email',
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 14),

          _MockupTextField(
            controller: passwordController,
            icon: Icons.lock_outline,
            hint: 'Password',
            obscureText: true,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Required' : null,
          ),

          // ── Forgot link (right-aligned, fs 10, color #666) ──
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 16),
              child: GestureDetector(
                onTap: onForgot,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: const Text(
                    'Forgot your Password?',
                    style: TextStyle(
                      fontSize: 10,
                      color: LobbyMockupTokens.inkMuted,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 10),
              color: const Color(0xFFFFE5E5),
              child: Text(
                errorMessage!,
                style: const TextStyle(
                  fontSize: 11,
                  color: LobbyMockupTokens.seatEliminatedInk,
                ),
              ),
            ),
          ],

          // ── Login button (black, full-width — mockup `.btn-login`) ──
          _MockupPrimaryButton(
            label: 'Login',
            submitting: submitting,
            onPressed: submitting ? null : onLogin,
          ),
          const SizedBox(height: 10),

          // ── Entra ID button (outlined, with brand square icon) ──
          _MockupEntraButton(
            onPressed: () {
              // TODO: Entra ID OAuth wiring (TBD).
            },
          ),
        ],
      ),
    );
  }
}

class _TotpForm extends StatelessWidget {
  const _TotpForm({
    required this.totpController,
    required this.submitting,
    required this.errorMessage,
    required this.onVerify,
    required this.onBack,
  });

  final TextEditingController totpController;
  final bool submitting;
  final String? errorMessage;
  final VoidCallback onVerify;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Enter your 2FA code',
          style: TextStyle(
            fontSize: 11,
            color: LobbyMockupTokens.inkSecondary,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: totpController,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontFamily: LobbyMockupTokens.fontFamilyMono,
            fontSize: 18,
            letterSpacing: 8,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
          decoration: InputDecoration(
            counterText: '',
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide:
                  const BorderSide(color: LobbyMockupTokens.inkSofter),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide:
                  const BorderSide(color: LobbyMockupTokens.inkSofter),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide:
                  const BorderSide(color: LobbyMockupTokens.inkSubdued),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 10),
            color: const Color(0xFFFFE5E5),
            child: Text(
              errorMessage!,
              style: const TextStyle(
                fontSize: 11,
                color: LobbyMockupTokens.seatEliminatedInk,
              ),
            ),
          ),
        ],
        _MockupPrimaryButton(
          label: 'Verify',
          submitting: submitting,
          onPressed: submitting ? null : onVerify,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onBack,
          style: TextButton.styleFrom(
            foregroundColor: LobbyMockupTokens.inkMuted,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 24),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Back',
            style: TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }
}

/// Mockup `.form-group` — icon + text input row.
class _MockupTextField extends StatelessWidget {
  const _MockupTextField({
    required this.controller,
    required this.icon,
    required this.hint,
    this.autofocus = false,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final bool autofocus;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          child: Icon(icon, size: 14, color: LobbyMockupTokens.inkSubdued),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: controller,
            autofocus: autofocus,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 11),
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 11,
                color: LobbyMockupTokens.inkPlaceholder,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide:
                    const BorderSide(color: LobbyMockupTokens.inkSofter),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide:
                    const BorderSide(color: LobbyMockupTokens.inkSofter),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide:
                    const BorderSide(color: LobbyMockupTokens.inkSubdued),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide:
                    const BorderSide(color: LobbyMockupTokens.btnDanger),
              ),
              errorStyle: const TextStyle(fontSize: 9),
            ),
          ),
        ),
      ],
    );
  }
}

/// Mockup `.btn-login` — black, full-width, fs 12 / weight 700.
class _MockupPrimaryButton extends StatelessWidget {
  const _MockupPrimaryButton({
    required this.label,
    required this.submitting,
    required this.onPressed,
  });

  final String label;
  final bool submitting;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 32,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: LobbyMockupTokens.btnPrimary,
          foregroundColor: LobbyMockupTokens.btnPrimaryInk,
          disabledBackgroundColor: LobbyMockupTokens.inkPlaceholder,
          elevation: 0,
          shape: const RoundedRectangleBorder(),
          padding: EdgeInsets.zero,
        ),
        child: submitting
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: LobbyMockupTokens.letterSpacingBtn,
                ),
              ),
      ),
    );
  }
}

/// Mockup `.btn-entra` — outlined, with blue square icon + (TBD) tag.
class _MockupEntraButton extends StatelessWidget {
  const _MockupEntraButton({required this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 30,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: LobbyMockupTokens.inkSecondary,
          backgroundColor: LobbyMockupTokens.bg,
          side: const BorderSide(color: LobbyMockupTokens.inkSofter),
          shape: const RoundedRectangleBorder(),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 14,
              height: 14,
              color: LobbyMockupTokens.btnEntraIcon,
            ),
            const SizedBox(width: 6),
            const Text(
              'Sign In With Entra ID',
              style: TextStyle(
                fontSize: 11,
                color: LobbyMockupTokens.inkSecondary,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '(TBD)',
              style: TextStyle(
                fontSize: 9,
                color: LobbyMockupTokens.inkDim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
