import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/responsive.dart';
import '../shared/background_pattern.dart';
import '../shared/ecowell_logo.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<({String title, String subtitle, String leafSubtitle})> _slides = const [
    (
      title: 'Empower your\nmind, elevate your life.',
      subtitle: 'Let us help you Prioritize your mental health with mindfulness and self-care.',
      leafSubtitle: 'Find your calm. Track your\ngrowth.',
    ),
    (
      title: 'Discover peaceful\ngreen spaces nearby.',
      subtitle: 'Explore parks, mangrove trails, and beaches rated with community Quiet Scores.',
      leafSubtitle: 'Connect with nature.\nReset stress.',
    ),
    (
      title: 'Track your Stress\nReduction Score.',
      subtitle: 'Measure your pre- and post-visit PSS-4 wellness delta after every nature immersion.',
      leafSubtitle: 'Science-backed\nmindfulness journeys.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: OrganicBackgroundCircles(
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: Responsive.size(context, 28)),

              // Brand Title
              Text(
                'EcoWell',
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 34),
                  fontWeight: FontWeight.w700,
                  fontFamily: 'serif',
                  color: Color(0xFF132A1F),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: Responsive.size(context, 12)),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _slides[_currentPage].leafSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 16),
                    color: Color(0xFF4C685A),
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),

              const Spacer(),

              // Center Circular Leaf Hero Badge
              Container(
                width: size.width * 0.46,
                height: size.width * 0.46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E6C54), Color(0xFF104434)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F3A2C).withValues(alpha: 0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Center(
                  child: EcoWellLeafIcon(
                    size: 76,
                    color: Color(0xFF8DE2C8),
                  ),
                ),
              ),

              const Spacer(),

              // Bottom Asymmetric Wave Curved Card
              ClipPath(
                clipper: _OnboardingWaveClipper(),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF65BA97), Color(0xFF1E503F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    Responsive.size(context, 28),
                    Responsive.size(context, 48),
                    Responsive.size(context, 28),
                    Responsive.size(context, 28),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: Responsive.size(context, 130),
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) => setState(() => _currentPage = index),
                          itemCount: _slides.length,
                          itemBuilder: (context, index) {
                            final slide = _slides[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  slide.title,
                                  style: TextStyle(
                                    fontSize: Responsive.fontSize(context, 23),
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.22,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  slide.subtitle,
                                  style: TextStyle(
                                    fontSize: Responsive.fontSize(context, 13),
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      SizedBox(height: Responsive.size(context, 16)),

                      // Bottom Controls: Pill indicator + Next Arrow
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Pill indicator matching mockup
                          Row(
                            children: List.generate(_slides.length, (index) {
                              final isSelected = index == _currentPage;
                              return Container(
                                margin: const EdgeInsets.only(right: 6),
                                width: isSelected ? Responsive.size(context, 40) : Responsive.size(context, 20),
                                height: Responsive.size(context, 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.white.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }),
                          ),

                          // Arrow Button
                          GestureDetector(
                            onTap: _onNext,
                            child: Container(
                              width: Responsive.size(context, 48),
                              height: Responsive.size(context, 48),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.16),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: Color(0xFF164837),
                                size: Responsive.size(context, 24),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Asymmetric curved wave clipper for the bottom card
class _OnboardingWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    // Start on the left partway down
    path.moveTo(0, 36);
    // Smooth wave sweeping up to the right
    path.cubicTo(
      size.width * 0.25, 0,
      size.width * 0.65, 44,
      size.width, 24,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
