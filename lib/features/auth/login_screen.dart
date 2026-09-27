import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/responsive.dart';
import '../shared/background_pattern.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).login(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).loginWithGoogle();
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('invalid-email')) return 'Enter a valid email address.';
    if (msg.contains('user-not-found')) return 'No account found with this email.';
    if (msg.contains('wrong-password')) return 'Incorrect password. Please try again.';
    if (msg.contains('too-many-requests')) return 'Too many attempts. Please try again later.';
    if (msg.contains('network-request-failed')) return 'Network error. Check your connection.';
    return msg.replaceAll('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: OrganicBackgroundCircles(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.horizontalPadding(context),
                vertical: Responsive.size(context, 24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: Responsive.size(context, 12)),

                  // "Login here" Title in vibrant green
                  Text(
                    'Login here',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 30),
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2E8B57),
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: Responsive.size(context, 16)),

                  // Subtitle
                  SizedBox(
                    width: MediaQuery.sizeOf(context).width * 0.65,
                    child: Text(
                      'Welcome back you\'ve\nbeen missed!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 20),
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF112217),
                        height: 1.3,
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.size(context, 46)),

                  // Email Field
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: const Color(0xFF112217), fontSize: Responsive.fontSize(context, 15)),
                    decoration: InputDecoration(
                      hintText: 'Email',
                      hintStyle: TextStyle(color: const Color(0xFF62776A), fontSize: Responsive.fontSize(context, 14)),
                      fillColor: const Color(0xFFFBFDFB),
                      filled: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: Responsive.size(context, 18),
                        vertical: Responsive.size(context, 16),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Responsive.radius(context, 14)),
                        borderSide: const BorderSide(color: Color(0xFF90D5B7), width: 1.6),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Responsive.radius(context, 14)),
                        borderSide: const BorderSide(color: Color(0xFF90D5B7), width: 1.6),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Responsive.radius(context, 14)),
                        borderSide: const BorderSide(color: Color(0xFF2E8B57), width: 2.0),
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.size(context, 18)),

                  // Password Field
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: TextStyle(color: const Color(0xFF112217), fontSize: Responsive.fontSize(context, 15)),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: TextStyle(color: const Color(0xFF62776A), fontSize: Responsive.fontSize(context, 14)),
                      fillColor: const Color(0xFFFBFDFB),
                      filled: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: Responsive.size(context, 18),
                        vertical: Responsive.size(context, 16),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Responsive.radius(context, 14)),
                        borderSide: const BorderSide(color: Color(0xFF90D5B7), width: 1.6),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Responsive.radius(context, 14)),
                        borderSide: const BorderSide(color: Color(0xFF90D5B7), width: 1.6),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Responsive.radius(context, 14)),
                        borderSide: const BorderSide(color: Color(0xFF2E8B57), width: 2.0),
                      ),
                    ),
                  ),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: Responsive.size(context, 8),
                        bottom: Responsive.size(context, 20),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password reset link sent to your email.')),
                          );
                        },
                        child: Text(
                          'Forgot your password?',
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 12),
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF112217),
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: TextStyle(color: Colors.red, fontSize: Responsive.fontSize(context, 13)),
                    ),
                    SizedBox(height: Responsive.size(context, 12)),
                  ],

                  // Sign In Action Button with Horizontal Mint-to-Forest Gradient
                  Container(
                    width: double.infinity,
                    height: Responsive.size(context, 54),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF75C19F), Color(0xFF1E5241)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(Responsive.radius(context, 14)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E5241).withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _loading ? null : _submit,
                        borderRadius: BorderRadius.circular(Responsive.radius(context, 14)),
                        child: Center(
                          child: _loading
                              ? SizedBox(
                                  width: Responsive.size(context, 24),
                                  height: Responsive.size(context, 24),
                                  child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: Responsive.fontSize(context, 18),
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: Responsive.size(context, 38)),

                  // Divider "or"
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: const Color(0xFFD6E8DF).withValues(alpha: 0.9),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: Responsive.size(context, 14)),
                        child: Text(
                          'or',
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 13),
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF778D80),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: const Color(0xFFD6E8DF).withValues(alpha: 0.9),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: Responsive.size(context, 18)),

                  // Google Sign In Button
                  Container(
                    width: double.infinity,
                    height: Responsive.size(context, 54),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(Responsive.radius(context, 14)),
                      border: Border.all(color: const Color(0xFFD6E8DF)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _loading ? null : _loginWithGoogle,
                        borderRadius: BorderRadius.circular(Responsive.radius(context, 14)),
                        child: Center(
                          child: _loading
                              ? SizedBox(
                                  width: Responsive.size(context, 24),
                                  height: Responsive.size(context, 24),
                                  child: const CircularProgressIndicator(color: Color(0xFF2E8B57), strokeWidth: 2.5),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.network(
                                      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                                      width: Responsive.size(context, 22),
                                      height: Responsive.size(context, 22),
                                      errorBuilder: (context, error, stackTrace) => Text(
                                        'G',
                                        style: TextStyle(
                                          fontSize: Responsive.fontSize(context, 22),
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFFEA4335),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: Responsive.size(context, 10)),
                                    Text(
                                      'Continue with Google',
                                      style: TextStyle(
                                        fontSize: Responsive.fontSize(context, 15),
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF112217),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: Responsive.size(context, 28)),

                  // Bottom Switch to Register
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 14),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF112217),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/register'),
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 14),
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2E8B57),
                          ),
                        ),
                      ),
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
}
