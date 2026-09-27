import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/responsive.dart';
import '../../providers/auth_provider.dart';
import '../shared/background_pattern.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_validateForm()) return;
    setState(() {
      _loading = true;
      _error = null;
      _success = false;
    });
    try {
      final age = int.tryParse(_ageController.text.trim()) ?? 25;
      await ref.read(authControllerProvider.notifier).register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            age: age,
            password: _passwordController.text,
          );
      if (mounted) {
        setState(() {
          _loading = false;
          _success = true;
        });
        await Future.delayed(const Duration(milliseconds: 700));
        if (mounted) context.go('/home');
      }
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted && !_success) setState(() => _loading = false);
    }
  }

  bool _validateForm() {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your name.');
      return false;
    }
    if (_emailController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your email.');
      return false;
    }
    if (_ageController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your age.');
      return false;
    }
    final age = int.tryParse(_ageController.text.trim());
    if (age == null || age < 18) {
      setState(() => _error = 'You must be at least 18 years old.');
      return false;
    }
    if (_passwordController.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'Passwords do not match.');
      return false;
    }
    return true;
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).loginWithGoogle();
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('email-already-in-use')) return 'An account already exists with this email.';
    if (msg.contains('invalid-email')) return 'Enter a valid email address.';
    if (msg.contains('weak-password')) return 'Password is too weak.';
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
                  SizedBox(height: Responsive.size(context, 8)),

                  // Header Title
                  Text(
                    'Create Account',
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
                      'Start your wellness\njourney today!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 20),
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF112217),
                        height: 1.3,
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.size(context, 38)),

                  // Success Confirmation Banner (above the form)
                  if (_success) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.size(context, 16),
                        vertical: Responsive.size(context, 14),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5EE),
                        borderRadius: BorderRadius.circular(Responsive.radius(context, 14)),
                        border: Border.all(color: const Color(0xFF2E8B57)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF2E8B57)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Account created successfully! Welcome to EcoWell 🌿',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E5241),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: Responsive.size(context, 18)),
                  ],

                  // Name Field
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(
                      color: const Color(0xFF112217),
                      fontSize: Responsive.fontSize(context, 15),
                    ),
                    decoration: _inputDecoration(context, 'Full Name'),
                  ),
                  SizedBox(height: Responsive.size(context, 18)),

                  // Email Field
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(
                      color: const Color(0xFF112217),
                      fontSize: Responsive.fontSize(context, 15),
                    ),
                    decoration: _inputDecoration(context, 'Email'),
                  ),
                  SizedBox(height: Responsive.size(context, 18)),

                  // Age Field
                  TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: const Color(0xFF112217),
                      fontSize: Responsive.fontSize(context, 15),
                    ),
                    decoration: _inputDecoration(context, 'Age'),
                  ),
                  SizedBox(height: Responsive.size(context, 18)),

                  // Password Field
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: TextStyle(
                      color: const Color(0xFF112217),
                      fontSize: Responsive.fontSize(context, 15),
                    ),
                    decoration: _inputDecoration(context, 'Password'),
                  ),
                  SizedBox(height: Responsive.size(context, 18)),

                  // Confirm Password Field
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    style: TextStyle(
                      color: const Color(0xFF112217),
                      fontSize: Responsive.fontSize(context, 15),
                    ),
                    decoration: _inputDecoration(context, 'Confirm Password'),
                  ),

                  if (_error != null) ...[
                    SizedBox(height: Responsive.size(context, 12)),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: Responsive.fontSize(context, 13),
                      ),
                    ),
                  ],

                  SizedBox(height: Responsive.size(context, 28)),

                  // Sign Up Action Button
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
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  'Sign Up',
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

                  SizedBox(height: Responsive.size(context, 22)),

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
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.size(context, 14),
                        ),
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

                  // Social Icons (Google / Facebook)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google Logo Button
                      _buildSocialIcon(
                        child: Image.network(
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
                        onTap: _loginWithGoogle,
                      ),
                      SizedBox(width: Responsive.size(context, 18)),

                      // Facebook Logo Button
                      _buildSocialIcon(
                        child: Icon(
                          Icons.facebook,
                          color: const Color(0xFF1877F2),
                          size: Responsive.size(context, 28),
                        ),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Facebook sign-in coming soon.')),
                          );
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: Responsive.size(context, 24)),

                  // Bottom Switch to Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 14),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF112217),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          'Sign In',
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

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: const Color(0xFF62776A),
        fontSize: Responsive.fontSize(context, 14),
      ),
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
    );
  }

  Widget _buildSocialIcon({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: Responsive.size(context, 44),
        height: Responsive.size(context, 44),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
