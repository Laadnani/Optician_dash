import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' as material;
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:optic/constants.dart';
import 'package:optic/controllers/tenant_session.dart';
import 'package:optic/controllers/theme_controller.dart';
import 'package:optic/localization/app_strings.dart';
import 'package:optic/responsive.dart';

/// The app's one pre-auth screen — shown by `_AuthGate` (see `main.dart`)
/// whenever `TenantSession.user` is null. No `AppShell`/sidebar here on
/// purpose: there's no shop context yet to show nav for.
///
/// Sign-in only — a shop's tenant + first owner account are provisioned
/// from the licensing website at purchase time (not from inside this app),
/// so there's no "create your shop" flow here. Staff for an
/// already-provisioned shop just sign in with the email/password set up
/// for them.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = material.TextEditingController();
  final _password = material.TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;
  String? _infoMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _email.text.trim().isNotEmpty && _password.text.trim().isNotEmpty;

  // Maps FirebaseAuthException's stable `code` values to the user-facing,
  // translated messages already defined in AppStrings, rather than
  // surfacing Firebase's own English-only exception text.
  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return AppStrings.authErrorInvalidCredentials;
      case 'invalid-email':
        return AppStrings.authErrorInvalidEmail;
      default:
        return AppStrings.authErrorGeneric;
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit || _isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _infoMessage = null;
    });
    final tenantSession = context.read<TenantSession>();
    try {
      await tenantSession.signIn(email: _email.text, password: _password.text);
      // No navigation here — `_AuthGate` in main.dart is watching
      // `TenantSession` and swaps to the app shell on its own once
      // `user`/`tenantId` are set.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = _messageFor(e));
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = AppStrings.authErrorGeneric);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _forgotPassword() async {
    if (_email.text.trim().isEmpty) return;
    final tenantSession = context.read<TenantSession>();
    try {
      await tenantSession.sendPasswordResetEmail(_email.text);
      if (!mounted) return;
      setState(() {
        _infoMessage = AppStrings.authResetPasswordSentMessage;
        _errorMessage = null;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = _messageFor(e));
    }
  }

  Widget _field({
    required String label,
    required material.TextEditingController controller,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: material.TextField(
        controller: controller,
        obscureText: obscure,
        decoration: material.InputDecoration(
          labelText: label,
          border: const material.OutlineInputBorder(),
          isDense: true,
          suffixIcon: suffixIcon,
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
      ),
    );
  }

  /// Lets a user pick their sign-in language before authenticating —
  /// applies immediately (no draft/save step, unlike Settings' staged
  /// scaling/color pickers) since this is just a one-tap convenience ahead
  /// of signing in, not a persisted preference someone tunes carefully.
  ///
  /// NOT a Material `DropdownButton`/`PopupMenuButton` — both push their menu
  /// via `Navigator.of(context)` under the hood, but `LoginScreen` is
  /// swapped in for whatever GoRouter would render (see `main.dart`'s auth
  /// gate: `return const LoginScreen();` instead of `child!`) rather than
  /// being nested inside the Router's Navigator, so any widget here that
  /// reaches for a Navigator throws "does not include a Navigator" — which
  /// is exactly the crash a real dropdown produced. A row of small toggle
  /// buttons (same widget already used for this same picker in
  /// settings_screen.dart) needs no Navigator/Overlay at all, so it can't
  /// hit that class of bug.
  Widget _languageDropdown(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < kLanguages.length; i++)
          Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
            child: Button(
              style: i == themeController.languageIndex
                  ? const ButtonStyle.primary()
                  : const ButtonStyle.ghost(),
              onPressed: () => themeController.setLanguageIndex(i),
              child: Text(kLanguages[i].code.toUpperCase()).small(),
            ),
          ),
      ],
    );
  }

  /// The actual sign-in form — logo, title, fields, messages, and the
  /// sign-in/forgot-password actions. Shared by both layouts below so the
  /// bound state (controllers, error/info messages, submit handlers) only
  /// lives in one place.
  Widget _formColumn(BuildContext context, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
            ),
            _languageDropdown(context),
          ],
        ),
        const SizedBox(height: 20),
        Text(AppStrings.authSignInTitle).large().bold(),
        const SizedBox(height: 24),
        _field(label: AppStrings.authEmailLabel, controller: _email),
        _field(
          label: AppStrings.authPasswordLabel,
          controller: _password,
          obscure: _obscurePassword,
          // Wrapped in its own `Material` ancestor (transparent, no visual
          // effect) since `IconButton`'s ink response needs one and this
          // screen sits directly under `ShadcnApp` rather than a
          // `MaterialApp` — safe/inert either way if an ancestor already
          // exists further up.
          suffixIcon: material.Material(
            type: material.MaterialType.transparency,
            child: material.IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                size: 18,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Button(
            style: const ButtonStyle.ghost(),
            onPressed: _forgotPassword,
            child: Text(AppStrings.authForgotPasswordLink).small(),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 4),
          Text(
            _errorMessage!,
            style: TextStyle(color: colorScheme.destructive),
          ).small(),
        ],
        if (_infoMessage != null) ...[
          const SizedBox(height: 4),
          Text(_infoMessage!).small().muted(),
        ],
        const SizedBox(height: 16),
        Button(
          style: const ButtonStyle.destructive(),
          onPressed: _canSubmit && !_isSubmitting ? _submit : null,
          // No more inline spinner here — the whole card shows a loading
          // overlay instead (see `_loadingOverlay`), so this just stays as
          // the plain (disabled-while-submitting) label.
          child: Text(AppStrings.authSignInButton),
        ),
      ],
    );
  }

  /// A gray, see-through scrim over the *entire* card — not just the
  /// button — shown while a sign-in is in flight. Replaces the old small
  /// spinner that used to live inside the sign-in button alone.
  /// `AbsorbPointer` blocks taps/hovers on the fields and buttons
  /// underneath for the duration, rather than just visually dimming them
  /// while leaving them clickable. Returns an empty widget (not `null`) so
  /// callers can drop it straight into a `Stack`'s `children` unconditionally.
  Widget _loadingOverlay() {
    if (!_isSubmitting) return const SizedBox.shrink();
    return Positioned.fill(
      child: AbsorbPointer(
        child: Container(
          color: Colors.gray.withOpacity(0.3),
          alignment: Alignment.center,
          child: const material.CircularProgressIndicator(),
        ),
      ),
    );
  }

  /// Right-hand brand panel for the desktop split layout — a plain tinted
  /// surface with the actual app logo centered on it (rather than any
  /// placeholder illustration/text), per the reference design adapted for
  /// this app's own branding.
  Widget _brandPanel(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.muted,
      alignment: Alignment.center,
      child: SizedBox(
        width: 140,
        height: 140,
        child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Desktop web gets the two-panel card (form + brand panel) from the
    // reference design; mobile/tablet keep the original simple centered
    // card untouched for now (a separate mobile design is still pending).
    if (Responsive.isDesktop(context)) {
      return Scaffold(
        // Fallback fill behind the background image (covers any edge the
        // `cover`-fitted image doesn't quite reach, and shows briefly while
        // the asset decodes) — same tint approach as
        // `ThemeController.backgroundColor` rather than a fixed hue.
        backgroundColor: Color.lerp(colorScheme.background, colorScheme.primary, 0.12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/login_background.png',
              fit: BoxFit.cover,
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      // 30% see-through per request — lets the background
                      // image show faintly behind the card itself, not just
                      // around it.
                      color: colorScheme.card.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 6,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 48,
                                    vertical: 48,
                                  ),
                                  child: _formColumn(context, colorScheme),
                                ),
                              ),
                              Expanded(
                                flex: 5,
                                child: _brandPanel(colorScheme),
                              ),
                            ],
                          ),
                        ),
                        _loadingOverlay(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mobile/tablet: same background image as desktop, per request — but
    // since there's no room for the brand side-panel here, the form gets
    // wrapped in its own card instead (it used to sit bare on the plain
    // page background, which read fine against a flat color but would get
    // lost against the now-busy background image).
    return Scaffold(
      backgroundColor: Color.lerp(colorScheme.background, colorScheme.primary, 0.12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/login_background.png', fit: BoxFit.cover),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    // 30% see-through, same as the desktop card.
                    color: colorScheme.card.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.14),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  // `padding` moved from this Container's own property into
                  // the inner `Padding` below so `_loadingOverlay()` — a
                  // `Positioned.fill` sibling in the `Stack` — covers the
                  // *entire* card (including what used to be the padded
                  // margin), not just the inner content area.
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(28),
                        child: _formColumn(context, colorScheme),
                      ),
                      _loadingOverlay(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
