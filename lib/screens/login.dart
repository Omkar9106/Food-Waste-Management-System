import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final savedEmail = await StorageService.getUserEmail();
    debugPrint('🔐 [Login] Loading saved email: $savedEmail');
    if (savedEmail != null && savedEmail.isNotEmpty) {
      _emailController.text = savedEmail;
      debugPrint('✅ [Login] Email pre-filled: ${_emailController.text}');
    } else {
      debugPrint('⚠️ [Login] No saved email found');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth > 600;
            final isSmallMobile = constraints.maxWidth < 380;
            
            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isWideScreen ? 48 : (isSmallMobile ? 16 : 24)),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWideScreen ? 500 : double.infinity,
                  ),
                  child: Card(
                    elevation: 8,
                    shadowColor: Colors.black.withOpacity(0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isWideScreen ? 48 : (isSmallMobile ? 24 : 32)),
                        child: AutofillGroup(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Logo
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryGreen.withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.restaurant_rounded,
                                    size: 56,
                                    color: Colors.white,
                                  ),
                                ).animate().scale(
                                  duration: 600.ms,
                                  curve: Curves.elasticOut,
                                ),
                                SizedBox(height: isSmallMobile ? 20 : 28),
                                
                                // Welcome Text
                                Text(
                                  'Welcome Back',
                                  style: Theme.of(context).textTheme.displaySmall,
                                ).animate().fadeIn(
                                  delay: 200.ms,
                                  duration: 400.ms,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Login to continue making a difference',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ).animate().fadeIn(
                                  delay: 300.ms,
                                  duration: 400.ms,
                                ),
                                SizedBox(height: isSmallMobile ? 28 : 40),

                                // Email Field
                                TextFormField(
                                  controller: _emailController,
                                  autofillHints: const [AutofillHints.email],
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  style: const TextStyle(
                                    color: Color(0xFF1E293B),
                                    fontSize: 16,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Email Address',
                                    hintText: 'Enter your email',
                                    prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF64748B)),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
                                    ),
                                    labelStyle: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 14,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty || !value.contains('@')) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                  onFieldSubmitted: (_) {
                                    FocusScope.of(context).nextFocus();
                                  },
                                ).animate().fadeIn(
                                  delay: 400.ms,
                                  duration: 400.ms,
                                ).slideY(
                                  begin: 0.2,
                                  duration: 400.ms,
                                ),

                                SizedBox(height: isSmallMobile ? 16 : 20),

                                // Password Field
                                TextFormField(
                                  controller: _passwordController,
                                  autofillHints: const [AutofillHints.password],
                                  obscureText: true,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _handleLogin(),
                                  style: const TextStyle(
                                    color: Color(0xFF1E293B),
                                    fontSize: 16,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    hintText: 'Enter your password',
                                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B)),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
                                    ),
                                    labelStyle: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 14,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ).animate().fadeIn(
                                  delay: 500.ms,
                                  duration: 400.ms,
                                ).slideY(
                                  begin: 0.2,
                                  duration: 400.ms,
                                ),

                                SizedBox(height: isSmallMobile ? 24 : 32),

                                // Login Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryGreen,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : const Text(
                                            'Login',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                  ),
                                ).animate().fadeIn(
                                  delay: 600.ms,
                                  duration: 400.ms,
                                ).slideY(
                                  begin: 0.2,
                                  duration: 400.ms,
                                ),

                                SizedBox(height: isSmallMobile ? 16 : 24),

                                // Sign Up Button
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/signup');
                                  },
                                  child: Text.rich(
                                    TextSpan(
                                      text: "Don't have an account? ",
                                      style: Theme.of(context).textTheme.bodyMedium,
                                      children: [
                                        TextSpan(
                                          text: 'Sign Up',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: AppTheme.primaryGreen,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ).animate().fadeIn(
                                  delay: 700.ms,
                                  duration: 400.ms,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ? LOGIN FUNCTION (clean & separated)
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Use controller values directly instead of onSaved
    final emailValue = _emailController.text.trim();
    final passwordValue = _passwordController.text;

    debugPrint('🔐 [Login] Attempting login with email: $emailValue');

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.login(emailValue, passwordValue);

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (result.success) {
        debugPrint('✅ [Login] Login successful');
        await authState.onLoginSuccess();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful!'),
            backgroundColor: Colors.green,
          ),
        );

        final userRole = authState.userRole;

        if (userRole == 'Donor') {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/donor_dashboard',
            (route) => false,
          );
        } else if (userRole == 'NGO') {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/ngo_dashboard',
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unknown user role'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        debugPrint('❌ [Login] Login failed: ${result.errorMessage}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.errorMessage ??
                  'Login failed. Please check your credentials.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [Login] Login error: $e');
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

