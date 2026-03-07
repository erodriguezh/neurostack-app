import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/constants/curves.dart';
import 'package:neurostack/core/ui/constants/durations.dart';
import 'package:neurostack/core/ui/widgets/app_grid_background.dart';
import 'package:neurostack/core/ui/widgets/dark_theme_scope.dart';

/// The splash screen displayed during app initialization.
///
/// Features:
/// - Dark background with subtle grid pattern
/// - Centered NeuroStack logo with breathing glow effect
/// - Premium entrance animations
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _breathingController;

  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _logoSlide;

  // Shader state
  ui.FragmentShader? _shader;
  late final AnimationController _shaderTimeController;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    _loadShader();
  }

  void _initAnimations() {
    // Entrance animation (500ms)
    _entranceController = AnimationController(
      duration: CustomDurations.instance.duration500,
      vsync: this,
    );

    // Breathing glow (2s, repeating)
    _breathingController = AnimationController(
      duration: CustomDurations.instance.duration1000 * 2,
      vsync: this,
    );

    // Logo entrance: fade + slide
    _logoOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: CustomCurves.easeOut,
    );

    _logoSlide =
        Tween<Offset>(
          begin: const Offset(0, -10),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: CustomCurves.easeOut,
          ),
        );

    // Shader time animation (continuous ticker)
    _shaderTimeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  void _startAnimations() {
    _entranceController.forward();
    _breathingController.repeat(reverse: true);
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset('shaders/beam.frag');
      if (mounted) {
        setState(() {
          _shader = program.fragmentShader();
        });
      }
    } catch (e) {
      debugPrint('Failed to load beam shader: $e');
    }
  }

  @override
  void dispose() {
    _shaderTimeController.dispose();
    _shader?.dispose();
    _entranceController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;

    return DarkThemeScope(
      child: Scaffold(
        backgroundColor: kitColors.background,
        body: Stack(
          children: [
            // Grid background
            Positioned.fill(
              child: GridPattern(
                lineColor: kitColors.white02,
              ),
            ),

            // Shader effect layer
            if (_shader != null)
              Positioned.fill(
                child: _ShaderBackground(
                  shader: _shader!,
                  animation: _shaderTimeController,
                ),
              ),

            // Logo
            Center(
              child: _AnimatedLogo(
                entranceAnimation: _logoOpacity,
                slideAnimation: _logoSlide,
                breathingAnimation: _breathingController,
                logoColor: kitColors.brandSky,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated logo widget with entrance and breathing glow effects.
class _AnimatedLogo extends StatelessWidget {
  const _AnimatedLogo({
    required this.entranceAnimation,
    required this.slideAnimation,
    required this.breathingAnimation,
    required this.logoColor,
  });

  final Animation<double> entranceAnimation;
  final Animation<Offset> slideAnimation;
  final Animation<double> breathingAnimation;
  final Color logoColor;

  static const double _logoSize = 64.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([entranceAnimation, breathingAnimation]),
      builder: (context, child) {
        // Breathing glow: opacity 0.2 → 0.4 → 0.2
        final breathValue = breathingAnimation.value;
        final innerOpacity = ui.lerpDouble(0.2, 0.4, breathValue)!;
        final outerOpacity = innerOpacity * 0.33;

        return FadeTransition(
          opacity: entranceAnimation,
          child: Transform.translate(
            offset: slideAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: logoColor.withValues(alpha: innerOpacity),
                    blurRadius: 20,
                  ),
                  BoxShadow(
                    color: logoColor.withValues(alpha: outerOpacity),
                    blurRadius: 40,
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
      child: SvgPicture.asset(
        'assets/logo.svg',
        width: _logoSize,
        height: _logoSize,
        colorFilter: ColorFilter.mode(logoColor, BlendMode.srcIn),
      ),
    );
  }
}

/// Shader background widget that renders the beam.frag effect.
class _ShaderBackground extends StatefulWidget {
  const _ShaderBackground({
    required this.shader,
    required this.animation,
  });

  final ui.FragmentShader shader;
  final Animation<double> animation;

  @override
  State<_ShaderBackground> createState() => _ShaderBackgroundState();
}

class _ShaderBackgroundState extends State<_ShaderBackground> {
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: widget.animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _ShaderPainter(
              shader: widget.shader,
              time: _stopwatch.elapsedMilliseconds / 1000.0,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _ShaderPainter extends CustomPainter {
  _ShaderPainter({
    required this.shader,
    required this.time,
  });

  final ui.FragmentShader shader;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    // Uniforms must match declaration order in beam.frag:
    // uniform float u_time;
    // uniform vec2 u_resolution;
    shader.setFloat(0, time);
    shader.setFloat(1, size.width);
    shader.setFloat(2, size.height);

    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(_ShaderPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}
