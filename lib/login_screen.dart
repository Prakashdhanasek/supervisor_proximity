import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supervisor_proximity/controllers/fleet_controller.dart';
import 'package:supervisor_proximity/services/auth_service.dart';
import 'package:supervisor_proximity/views/supervisor_shell.dart';
import 'package:supervisor_proximity/views/theme/app_theme.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    
    try {
      final auth = AuthService.instance;
      await auth.login(
        email: _email.text.trim(),
        password: _password.text,
      );
      
      if (!mounted) return;
      
      // Update FleetController with supervisor name
      if (auth.fullName != null) {
        context.read<FleetController>().setSupervisorIdentity(
          name: auth.fullName,
          email: auth.email,
        );
      }
      
      _goToApp();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
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
    return Scaffold(
      body: Container(
        width: double.infinity,

        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/login_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(


                  children: [

                    _brand(context),

                    // White login card
                    Padding(
                      padding: const EdgeInsets.only(top: 108.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Welcome back',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sign in to your fleet control console',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 24),
                              _label('EMAIL'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF1E293B)),
                                decoration: _input(
                                  context,
                                  hint: 'supervisor@proximity.com',
                                  icon: Icons.mail_outline_rounded,
                                ),
                                validator: (v) => (v == null || v.trim().length < 3) ? 'Enter your email' : null,
                              ),
                              const SizedBox(height: 20),
                              _label('PASSWORD'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _password,
                                obscureText: _obscure,
                                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF1E293B)),
                                decoration: _input(
                                  context,
                                  hint: 'Password',
                                  icon: Icons.lock_outline_rounded,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                      size: 20,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (v) => (v == null || v.length < 4) ? 'Password must be at least 4 characters' : null,
                                onFieldSubmitted: (_) => _signIn(),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () => _forgot(context),
                                  child: Text(
                                    'Forgot Password?',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF2B72F5),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              _signInButton(context),
                              const SizedBox(height: 24),
                              // Feature Row: Secure | AI Monitoring | Privacy First
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _featureItem(Icons.verified_user_outlined, 'Secure'),
                                  _divider(),
                                  _featureItem(Icons.videocam_outlined, 'AI Monitoring'),
                                  _divider(),
                                  _featureItem(Icons.lock_outline_rounded, 'Privacy First'),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Support Footer
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Need help? ',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {},
                                    child: Text(
                                      'Contact Support',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF2B72F5),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.headset_mic_outlined,
                                    size: 14,
                                    color: Color(0xFF2B72F5),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _brand(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/proximity.png',
width: 300,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 8),

      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF64748B),
        letterSpacing: 0.5,
      ),
    );
  }

  InputDecoration _input(BuildContext context, {required String hint, required IconData icon, Widget? suffix}) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: 1.0),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF94A3B8)),
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      enabledBorder: border(const Color(0xFFE2E8F0)),
      focusedBorder: border(const Color(0xFF2B72F5)),
      errorBorder: border(AppTheme.danger),
      focusedErrorBorder: border(AppTheme.danger),
      errorStyle: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.danger),
    );
  }

  Widget _signInButton(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _loading ? null : _signIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2B72F5),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sign in',
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _featureItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: const Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      height: 14,
      width: 1,
      color: const Color(0xFFE2E8F0),
    );
  }

  void _forgot(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reset password',
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
        ),
        content: Text(
          'A reset link will be sent to your registered email. Contact your fleet admin if you no longer have access.',
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reset link sent'), behavior: SnackBarBehavior.floating),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B72F5),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Send link'),
          ),
        ],
      ),
    );
  }
}