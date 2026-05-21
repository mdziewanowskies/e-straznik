import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/supabase_provider.dart';
import '../services/error_messages.dart';
import '../theme/colors.dart';
import '../widgets/mascot.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;
      HapticFeedback.lightImpact();
      // Wymuś nawigację — uniknięcie race condition z guardem routera.
      context.go('/dashboard');
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() => _error = mapErrorToPolish(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboardOpen = media.viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Hero gradient header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: keyboardOpen ? 180 : 320,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: const BoxDecoration(
                gradient: AppColors.gradientHero,
              ),
              child: SafeArea(
                bottom: false,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: keyboardOpen
                      ? const SizedBox.shrink()
                      : const _HeroContent(),
                ),
              ),
            ),
          ),
          // Form card
          Positioned.fill(
            top: keyboardOpen ? 160 : 260,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 0,
                bottom: media.viewInsets.bottom + 24,
              ),
              child: _LoginCard(
                formKey: _formKey,
                emailController: _emailController,
                passwordController: _passwordController,
                obscure: _obscure,
                error: _error,
                loading: _loading,
                onSubmit: _signIn,
                onToggleObscure: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Mascot(size: 130),
          SizedBox(height: 6),
          Text(
            'e-Strażnik',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscure,
    required this.error,
    required this.loading,
    required this.onSubmit,
    required this.onToggleObscure,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscure;
  final String? error;
  final bool loading;
  final VoidCallback onSubmit;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A101A33),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Zaloguj się',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.foreground,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Witaj z powrotem.',
              style: TextStyle(color: AppColors.mutedFg, fontSize: 13),
            ),
            const SizedBox(height: 24),
            _Label('Email'),
            const SizedBox(height: 6),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              style: const TextStyle(
                  color: AppColors.foreground, fontSize: 15),
              cursorColor: AppColors.primary,
              decoration: const InputDecoration(
                hintText: 'twoj@email.pl',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Podaj email';
                if (!v.contains('@')) return 'Niepoprawny email';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _Label('Hasło'),
            const SizedBox(height: 6),
            TextFormField(
              controller: passwordController,
              obscureText: obscure,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => onSubmit(),
              style: const TextStyle(
                  color: AppColors.foreground, fontSize: 15),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  splashRadius: 20,
                  icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                  onPressed: onToggleObscure,
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Podaj hasło' : null,
            ),
            if (error != null) ...[
              const SizedBox(height: 14),
              _ErrorBox(message: error!),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: loading ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.primaryFg,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.5),
                  disabledForegroundColor: Colors.white70,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Zaloguj się',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.info_outline,
                        size: 16, color: AppColors.teal),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Konto firmowe tworzysz w panelu webowym e-strażnika.',
                      style: TextStyle(
                        color: AppColors.foreground.withValues(alpha: 0.75),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: AppColors.foreground,
        letterSpacing: 0.1,
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
