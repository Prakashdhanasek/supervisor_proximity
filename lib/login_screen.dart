import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supervisor_proximity/views/supervisor_shell.dart';
import 'package:supervisor_proximity/views/theme/app_theme.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController(text: 'supervisor@fleet.com');
  final _password = TextEditingController();
  bool _obscure = true;
  bool _remember = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    // if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    // Simulated auth — replace with a real call to the cloud backend.
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    _goToApp();
  }

  void _biometric() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Authenticating with Face ID…'), behavior: SnackBarBehavior.floating),
    );
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _goToApp();
    });
  }

  void _goToApp() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const SupervisorShell(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _brand(context),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: AppTheme.cardDecoration(context),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Welcome back',
                              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                          const SizedBox(height: 2),
                          Text('Sign in to your fleet control console',
                              style: GoogleFonts.poppins(fontSize: 12, color: colors.textMuted)),
                          const SizedBox(height: 22),
                          _label(context, 'Email or company ID'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _input(context, hint: 'you@company.com', icon: Icons.alternate_email_rounded),
                            validator: (v) => (v == null || v.trim().length < 3) ? 'Enter your email or company ID' : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _label(context, 'Password'),
                              GestureDetector(
                                onTap: () => _forgot(context),
                                child: Text('Forgot?',
                                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _password,
                            obscureText: _obscure,
                            decoration: _input(
                              context,
                              hint: '••••••••',
                              icon: Icons.lock_outline_rounded,
                              suffix: IconButton(
                                icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                    size: 19, color: colors.textMuted),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) => (v == null || v.length < 4) ? 'Password must be at least 4 characters' : null,
                            onFieldSubmitted: (_) => _signIn(),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: Checkbox(
                                  value: _remember,
                                  onChanged: (v) => setState(() => _remember = v ?? false),
                                  activeColor: AppTheme.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('Keep me signed in',
                                  style: GoogleFonts.poppins(fontSize: 12, color: colors.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _signInButton(context),
                          const SizedBox(height: 16),
                          // _orDivider(context),
                          // const SizedBox(height: 16),
                          // OutlinedButton.icon(
                          //   onPressed: _loading ? null : _biometric,
                          //   icon: const Icon(Icons.face_rounded, size: 19),
                          //   label: const Text('Sign in with biometrics'),
                          //   style: OutlinedButton.styleFrom(
                          //     foregroundColor: colors.textPrimary,
                          //     side: BorderSide(color: colors.cardBorder),
                          //     padding: const EdgeInsets.symmetric(vertical: 14),
                          //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user_rounded, size: 13, color: colors.textMuted),
                      const SizedBox(width: 6),
                      Text('MFA-ready · secured by Proximity Guard',
                          style: GoogleFonts.poppins(fontSize: 10, color: colors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _brand(BuildContext context) {
    final colors = AppTheme.of(context);
    return Column(
      children: [
        Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: const Icon(Icons.shield_moon_rounded, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 16),
        Text('Proximity Guard',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary)),
        Text('Supervisor Console',
            style: GoogleFonts.poppins(fontSize: 12, color: colors.textMuted, letterSpacing: 1)),
      ],
    );
  }

  Widget _label(BuildContext context, String text) => Text(text,
      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.of(context).textSecondary));

  InputDecoration _input(BuildContext context, {required String hint, required IconData icon, Widget? suffix}) {
    final colors = AppTheme.of(context);
    OutlineInputBorder border(Color c) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c));
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 13, color: colors.textMuted),
      prefixIcon: Icon(icon, size: 19, color: colors.textMuted),
      suffixIcon: suffix,
      filled: true,
      fillColor: colors.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
      enabledBorder: border(colors.cardBorder),
      focusedBorder: border(AppTheme.primary),
      errorBorder: border(AppTheme.danger),
      focusedErrorBorder: border(AppTheme.danger),
      errorStyle: GoogleFonts.poppins(fontSize: 10, color: AppTheme.danger),
    );
  }

  Widget _signInButton(BuildContext context) {
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _loading ? null : AppTheme.primaryGradient,
          color: _loading ? AppTheme.primary.withValues(alpha: 0.6) : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: _loading
              ? null
              : [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: ElevatedButton(
          onPressed: _loading ? null : _signIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _loading
              ? const SizedBox(
                  width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Text('Sign in', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      ),
    );
  }

  // Widget _orDivider(BuildContext context) {
  //   final colors = AppTheme.of(context);
  //   return Row(
  //     children: [
  //       Expanded(child: Divider(color: colors.cardBorder)),
  //       Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 10),
  //         child: Text('or', style: GoogleFonts.poppins(fontSize: 11, color: colors.textMuted)),
  //       ),
  //       Expanded(child: Divider(color: colors.cardBorder)),
  //     ],
  //   );
  // }

  void _forgot(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.of(context).card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reset password',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.of(context).textPrimary)),
        content: Text('A reset link will be sent to your registered email. Contact your fleet admin if you no longer have access.',
            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.of(context).textSecondary, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reset link sent'), behavior: SnackBarBehavior.floating),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, elevation: 0),
            child: const Text('Send link'),
          ),
        ],
      ),
    );
  }
}