import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supervisor_proximity/login_screen.dart';
import 'package:supervisor_proximity/services/app_update_service.dart';
import 'package:supervisor_proximity/services/auth_service.dart';
import 'package:supervisor_proximity/views/supervisor_shell.dart';
import 'package:provider/provider.dart';
import 'package:supervisor_proximity/controllers/fleet_controller.dart';

/// Animated splash for the Supervisor app. Mirrors the driver app's brand
/// treatment (deep navy, orbit rings, shield wordmark) but is badged
/// "SUPERVISOR" and routes to the login page.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _master;
  late final AnimationController _pulse;
  late final AnimationController _rotate;
  late final AnimationController _particles;

  late final Animation<double> _bgGlow;
  late final Animation<double> _shieldScale;
  late final Animation<double> _shieldOpacity;
  late final Animation<double> _ringExpand;
  late final Animation<double> _ringOpacity;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _dividerWidth;
  late final Animation<double> _bottomOpacity;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _rotateAnim;
  late final Animation<double> _particleAnim;
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = 'v${info.version}');
    });
    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _rotate = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    );
    _particles = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    );

    _bgGlow = _curve(0, 0.2, Curves.easeOut);
    _shieldScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.1, 0.4, curve: Curves.elasticOut),
      ),
    );
    _shieldOpacity = _curve(0.1, 0.25, Curves.easeOut);
    _ringExpand = _curve(0.25, 0.5, Curves.easeOutCubic);
    _ringOpacity = _curve(0.25, 0.4, Curves.easeOut);
    _titleOpacity = _curve(0.4, 0.6, Curves.easeOut);
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _master,
            curve: const Interval(0.4, 0.65, curve: Curves.easeOutCubic),
          ),
        );
    _taglineOpacity = _curve(0.55, 0.75, Curves.easeOut);
    _dividerWidth = _curve(0.5, 0.7, Curves.easeOutCubic);
    _bottomOpacity = _curve(0.7, 0.9, Curves.easeOut);
    _pulseAnim = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    _rotateAnim = Tween<double>(begin: 0, end: 2 * math.pi).animate(_rotate);
    _particleAnim = Tween<double>(begin: 0, end: 1).animate(_particles);

    _run();
  }

  Animation<double> _curve(double begin, double end, Curve c) =>
      Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _master,
          curve: Interval(begin, end, curve: c),
        ),
      );

  Future<void> _run() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _master.forward();
    _rotate.repeat();
    _particles.repeat();
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _pulse.repeat(reverse: true);
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    // Check for app update before navigating
    final canProceed = await AppUpdateService.instance.checkForUpdate(context);
    if (!canProceed || !mounted) return;

    final bool isLoggedIn = AuthService.instance.isLoggedIn;
    if (isLoggedIn) {
      context.read<FleetController>().setSupervisorIdentity(
        name: AuthService.instance.fullName,
        email: AuthService.instance.email,
      );
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            isLoggedIn ? const SupervisorShell() : const LoginView(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _master.dispose();
    _pulse.dispose();
    _rotate.dispose();
    _particles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF050B18),
      body: AnimatedBuilder(
        animation: Listenable.merge([_master, _pulse, _rotate, _particles]),
        builder: (context, _) {
          return Stack(
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.3),
                    radius: 1.2,
                    colors: [Color(0xFF0A1628), Color(0xFF050B18)],
                  ),
                ),
                child: SizedBox.expand(),
              ),
              Positioned(
                top: size.height * 0.22,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _bgGlow.value * 0.6,
                  child: Container(
                    height: 280,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF1D4ED8).withValues(alpha: 0.25),
                          const Color(0xFF1D4ED8).withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.4, 1],
                      ),
                    ),
                  ),
                ),
              ),
              ...List.generate(16, (i) => _particle(i, size)),
              Center(
                child: Opacity(
                  opacity: _ringOpacity.value * 0.35,
                  child: Transform.rotate(
                    angle: _rotateAnim.value,
                    child: Transform.scale(
                      scale: 0.6 + (_ringExpand.value * 0.4),
                      child: CustomPaint(
                        size: const Size(280, 280),
                        painter: _OrbitRingPainter(
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: Opacity(
                  opacity: _ringOpacity.value * 0.2,
                  child: Transform.rotate(
                    angle: -_rotateAnim.value * 0.6,
                    child: Transform.scale(
                      scale: 0.7 + (_ringExpand.value * 0.3),
                      child: CustomPaint(
                        size: const Size(340, 340),
                        painter: _OrbitRingPainter(
                          color: const Color(0xFF60A5FA),
                          dashCount: 40,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      const Spacer(flex: 5),
                      Opacity(
                        opacity: _shieldOpacity.value,
                        child: Transform.scale(
                          scale: _shieldScale.value,
                          child: _shieldLogo(),
                        ),
                      ),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: 60 * _dividerWidth.value,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1),
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                Color(0xFF3B82F6),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SlideTransition(
                        position: _titleSlide,
                        child: Opacity(
                          opacity: _titleOpacity.value,
                          child: Column(
                            children: [
                              Text(
                                'PROXIMITY',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 11,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              ShaderMask(
                                shaderCallback: (b) => const LinearGradient(
                                  colors: [
                                    Color(0xFF60A5FA),
                                    Color(0xFF3B82F6),
                                    Color(0xFF818CF8),
                                  ],
                                ).createShader(b),
                                child: Text(
                                  'GUARD',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 44,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 15,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Opacity(
                        opacity: _taglineOpacity.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(
                                0xFF3B82F6,
                              ).withValues(alpha: 0.3),
                            ),
                            color: const Color(
                              0xFF3B82F6,
                            ).withValues(alpha: 0.08),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.shield_moon_rounded,
                                size: 13,
                                color: Color(0xFF93C5FD),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'S U P E R V I S O R',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF93C5FD),
                                  letterSpacing: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(flex: 4),
                      Opacity(
                        opacity: _bottomOpacity.value,
                        child: Column(
                          children: [
                            _dotsLoader(),
                            const SizedBox(height: 20),
                            Text(
                              'Connecting to fleet control…',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF475569),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _version,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _shieldLogo() {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: _pulseAnim.value * 1.2,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF3B82F6).withValues(alpha: 0.12),
                    const Color(0xFF3B82F6).withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.6, 1],
                ),
              ),
            ),
          ),
          Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
              ),
            ),
          ),
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment(-0.8, -1),
                end: Alignment(0.8, 1),
                colors: [
                  Color(0xFF2563EB),
                  Color(0xFF1D4ED8),
                  Color(0xFF1E40AF),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: const Color(0xFF1D4ED8).withValues(alpha: 0.3),
                  blurRadius: 80,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
          CustomPaint(size: const Size(52, 58), painter: _ShieldIconPainter()),
        ],
      ),
    );
  }

  Widget _particle(int index, Size screen) {
    final r = math.Random(index * 42);
    final startX = r.nextDouble() * screen.width;
    final startY = r.nextDouble() * screen.height;
    final drift = 20.0 + r.nextDouble() * 40;
    final pSize = 1.5 + r.nextDouble() * 2.5;
    final phase = r.nextDouble();
    final speed = 0.3 + r.nextDouble() * 0.7;
    final progress = ((_particleAnim.value * speed) + phase) % 1.0;
    final opacity = math.sin(progress * math.pi) * (0.3 + r.nextDouble() * 0.4);
    return Positioned(
      left: startX + math.sin(progress * math.pi * 2) * 10,
      top: startY - drift * progress,
      child: Opacity(
        opacity: (_bgGlow.value * opacity).clamp(0.0, 1.0),
        child: Container(
          width: pSize,
          height: pSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index % 3 == 0
                ? const Color(0xFF60A5FA)
                : index % 3 == 1
                ? const Color(0xFF818CF8)
                : const Color(0xFF93C5FD),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dotsLoader() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final t = ((_particleAnim.value * 3 + i * 0.18) % 1.0);
        final scale = 0.6 + 0.4 * math.sin(t * math.pi);
        final opacity = 0.3 + 0.7 * math.sin(t * math.pi);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3B82F6),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _OrbitRingPainter extends CustomPainter {
  final Color color;
  final int dashCount;
  _OrbitRingPainter({required this.color, this.dashCount = 60});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const dashFraction = 0.4;
    final dashArc = (2 * math.pi / dashCount) * dashFraction;
    final gapArc = (2 * math.pi / dashCount) * (1 - dashFraction);
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * (dashArc + gapArc),
        dashArc,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ShieldIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final shieldPath = Path()
      ..moveTo(w * 0.5, 0)
      ..quadraticBezierTo(w * 0.05, h * 0.08, w * 0.08, h * 0.38)
      ..quadraticBezierTo(w * 0.1, h * 0.68, w * 0.5, h)
      ..quadraticBezierTo(w * 0.9, h * 0.68, w * 0.92, h * 0.38)
      ..quadraticBezierTo(w * 0.95, h * 0.08, w * 0.5, 0)
      ..close();
    canvas.drawPath(
      shieldPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.8),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.drawPath(
      shieldPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    // A small radar / monitoring glyph instead of a tick, to read as "oversight".
    final pen = Paint()
      ..color = const Color(0xFF1D4ED8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawCircle(Offset(w * 0.5, h * 0.48), w * 0.1, pen);
    canvas.drawLine(Offset(w * 0.5, h * 0.48), Offset(w * 0.66, h * 0.32), pen);
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.48),
      2,
      Paint()..color = const Color(0xFF1D4ED8),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
