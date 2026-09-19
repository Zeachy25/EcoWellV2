import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../providers/auth_provider.dart';
import '../shared/background_pattern.dart';
import '../shared/ecowell_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      final auth = ref.read(authControllerProvider);
      if (auth.isAuthenticated) {
        context.go('/home');
      } else {
        context.go('/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: OrganicBackgroundCircles(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: Responsive.size(context, 110),
                    height: Responsive.size(context, 110),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF38B289), Color(0xFF143D2B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.forestMid.withValues(alpha: 0.25),
                          blurRadius: Responsive.size(context, 28),
                          offset: Offset(0, Responsive.size(context, 10)),
                        ),
                      ],
                    ),
                    child: Center(
                      child: EcoWellLeafIcon(size: Responsive.size(context, 54), color: Colors.white),
                    ),
                  ),
                  SizedBox(height: Responsive.size(context, 24)),
                  Text(
                    'EcoWell',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 36),
                      fontWeight: FontWeight.w800,
                      fontFamily: 'serif',
                      color: AppColors.forestDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: Responsive.size(context, 8)),
                  Text(
                    'Nature-Based Mental Wellness',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 14),
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
