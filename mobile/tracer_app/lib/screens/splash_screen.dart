import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late AnimationController _rotationCtrl;
  late AnimationController _progressCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _progressAnim;

  int _bootStep = 0;
  int _loadPercent = 0;
  Timer? _navTimer;

  final List<String> _bootMessages = const [
    'Initializing secure honeypot grid...',
    'Synchronizing cyber intelligence nodes...',
    'Encrypting surveillance channels...',
    'TRACER SENTINEL GRID ONLINE ✓',
  ];

  @override
  void initState() {
    super.initState();

    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _rotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _mainCtrl, curve: Curves.easeIn),
    );
    _scaleAnim = Tween<double>(begin: 0.75, end: 1).animate(
      CurvedAnimation(parent: _mainCtrl, curve: Curves.elasticOut),
    );
    _progressAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut),
    );

    _mainCtrl.forward();
    _progressCtrl.forward();

    // Boot messages cycling
    Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() { _bootStep = 1; _loadPercent = 25; });
    });
    Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() { _bootStep = 2; _loadPercent = 60; });
    });
    Timer(const Duration(milliseconds: 2100), () {
      if (mounted) setState(() { _bootStep = 3; _loadPercent = 100; });
    });

    _navTimer = Timer(const Duration(milliseconds: 3200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(
              opacity: anim,
              child: child,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _mainCtrl.dispose();
    _rotationCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF060C1A), Color(0xFF0A0F1D), Color(0xFF0D1526)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Particle starfield background
            Positioned.fill(
              child: CustomPaint(painter: _StarfieldPainter()),
            ),
            // Main content
            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAnimatedLogo(),
                      const SizedBox(height: 32),
                      // TRACER title with cyan glow
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppConstants.accentGradient.createShader(bounds),
                        child: const Text(
                          'TRACER',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 46,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppConstants.accent.withValues(alpha: 0.08),
                          border: Border.all(
                            color: AppConstants.accent.withValues(alpha: 0.4),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Text(
                          'TRACK  •  REPORT  •  PROTECT',
                          style: TextStyle(
                            color: AppConstants.accent,
                            fontSize: 10,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 56),

                      // Loading percentage counter
                      TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: _loadPercent),
                        duration: const Duration(milliseconds: 600),
                        builder: (_, val, __) => Text(
                          '$val%',
                          style: const TextStyle(
                            color: AppConstants.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Progress bar
                      SizedBox(
                        width: 240,
                        child: AnimatedBuilder(
                          animation: _progressAnim,
                          builder: (_, __) => ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: LinearProgressIndicator(
                              value: _progressAnim.value,
                              minHeight: 3,
                              backgroundColor:
                                  AppConstants.divider.withValues(alpha: 0.5),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppConstants.accent),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Boot message with typewriter feel
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: Text(
                          _bootMessages[_bootStep],
                          key: ValueKey<int>(_bootStep),
                          style: TextStyle(
                            color: _bootStep == 3
                                ? AppConstants.success
                                : AppConstants.textSecondary,
                            fontSize: 11,
                            letterSpacing: 0.8,
                            fontFamily: 'monospace',
                            fontWeight: _bootStep == 3
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _rotationCtrl,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          // Outer slow-rotating ring (dashed feel)
          Transform.rotate(
            angle: _rotationCtrl.value * 2 * math.pi,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppConstants.accent.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppConstants.accent,
                        boxShadow: [
                          BoxShadow(
                            color: AppConstants.accent.withValues(alpha: 0.8),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppConstants.success.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Counter-rotating inner ring
          Transform.rotate(
            angle: -_rotationCtrl.value * 2 * math.pi * 0.6,
            child: Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppConstants.accentBlue.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
            ),
          ),

          // Middle pulsing ring
          Container(
            width: 95,
            height: 95,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppConstants.accent.withValues(alpha: 0.05),
              border: Border.all(
                color: AppConstants.accent.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),

          // Inner shield core — cyan obsidian
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFF1A3A5C), Color(0xFF0A1A2E)],
              ),
              border: Border.all(
                color: AppConstants.accent.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.accent.withValues(alpha: 0.5),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: AppConstants.accentBlue.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.security_rounded,
              color: AppConstants.accent,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Starfield Background Painter ─────────────────────────────────────────
class _StarfieldPainter extends CustomPainter {
  final List<Offset> _stars = const [
    Offset(0.05, 0.1),  Offset(0.9, 0.05), Offset(0.3, 0.2),
    Offset(0.7, 0.15),  Offset(0.15, 0.4), Offset(0.85, 0.35),
    Offset(0.45, 0.08), Offset(0.6, 0.55), Offset(0.2, 0.7),
    Offset(0.8, 0.65),  Offset(0.5, 0.85), Offset(0.1, 0.9),
    Offset(0.95, 0.75), Offset(0.4, 0.95), Offset(0.75, 0.9),
    Offset(0.25, 0.55), Offset(0.55, 0.3), Offset(0.65, 0.78),
    Offset(0.35, 0.45), Offset(0.88, 0.5),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < _stars.length; i++) {
      final s = _stars[i];
      final r = (i % 3 == 0) ? 1.5 : ((i % 2 == 0) ? 1.0 : 0.6);
      final alpha = (i % 4 == 0) ? 0.6 : ((i % 3 == 0) ? 0.4 : 0.25);
      canvas.drawCircle(
        Offset(s.dx * size.width, s.dy * size.height),
        r,
        Paint()..color = const Color(0xFF00F2FE).withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter _) => false;
}
