import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../services/supabase_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );
    _progressController.forward();

    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final destination = SupabaseService.isAuthenticated
        ? const DashboardScreen()
        : const OnboardingScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => destination,
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Decorative blurred circles for premium feel
          _buildBackgroundDecoration(),

          // Main content
          SafeArea(
            child: SizedBox.expand(
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // Logo + Title + Loading
                  _buildIdentitySection(),

                  const Spacer(flex: 3),

                  // Footer
                  _buildFooterSection(),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),

          // Bottom accent line
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 128,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.white20,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecoration() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.1,
        child: Stack(
          children: [
            Positioned(
              top: -80,
              left: -80,
              child: Container(
                width: 384,
                height: 384,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.white,
                      blurRadius: 120,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              right: -80,
              child: Container(
                width: 384,
                height: 384,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.white,
                      blurRadius: 120,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentitySection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo container
        _buildLogoContainer(),

        const SizedBox(height: 24),

        // App name
        const Text(
          'SALGURI',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 36,
            fontWeight: FontWeight.w700,
            letterSpacing: 5.4,
            height: 1.2,
          ),
        ),

        const SizedBox(height: 48),

        // Loading indicator
        _buildLoadingIndicator(),
      ],
    );
  }

  Widget _buildLogoContainer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.white10,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.white20),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.25),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: _buildLogoIcon(),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoIcon() {
    return Image.asset(
      'assets/images/icon.png',
      width: 64,
      height: 64,
      fit: BoxFit.contain,
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 192,
      child: Column(
        children: [
          // Progress bar with shimmer
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  // Background track
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white20,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Animated fill
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _progressAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    },
                  ),
                  // Shimmer overlay
                  AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, child) {
                      return ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: const [
                              Colors.transparent,
                              Color(0x66FFFFFF),
                              Colors.transparent,
                            ],
                            stops: [
                              _shimmerController.value - 0.3,
                              _shimmerController.value,
                              _shimmerController.value + 0.3,
                            ].map((s) => s.clamp(0.0, 1.0)).toList(),
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.srcATop,
                        child: Container(
                          color: AppColors.white,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Status text
          Text(
            AppStrings.initializing.toUpperCase(),
            style: const TextStyle(
              color: AppColors.white60,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // Tagline
          Text(
            AppStrings.tagline,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.9),
              fontSize: 18,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 32),

          // Version info
          Column(
            children: [
              Text(
                AppStrings.versionLabel.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.white40,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                AppStrings.version,
                style: TextStyle(
                  color: AppColors.white50,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
