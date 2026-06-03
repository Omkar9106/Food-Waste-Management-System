import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  String email = '';
  String password = '';
  String confirmPassword = '';
  String role = 'Donor';
  bool _isLoading = false;

  @override
  void dispose() {
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
                                'Create Account',
                                style: Theme.of(context).textTheme.displaySmall,
                              ).animate().fadeIn(
                                delay: 200.ms,
                                duration: 400.ms,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sign up to start making a difference',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ).animate().fadeIn(
                                delay: 300.ms,
                                duration: 400.ms,
                              ),
                              SizedBox(height: isSmallMobile ? 24 : 40),

                              // Email Field
                              TextFormField(
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
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) => value!.isEmpty || !value.contains('@') ? 'Please enter a valid email' : null,
                                onSaved: (value) => email = value!,
                              ).animate().fadeIn(
                                delay: 400.ms,
                                duration: 400.ms,
                              ).slideY(
                                begin: 0.2,
                                duration: 400.ms,
                              ),

                              SizedBox(height: isSmallMobile ? 12 : 20),

                              // Password Field
                              TextFormField(
                                controller: _passwordController,
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
                                obscureText: true,
                                validator: (value) => value!.length < 6 ? 'Password must be at least 6 characters' : null,
                                onSaved: (value) => password = value!,
                              ).animate().fadeIn(
                                delay: 500.ms,
                                duration: 400.ms,
                              ).slideY(
                                begin: 0.2,
                                duration: 400.ms,
                              ),

                              SizedBox(height: isSmallMobile ? 12 : 20),

                              // Confirm Password Field
                              TextFormField(
                                style: const TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  hintText: 'Confirm your password',
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
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                                onSaved: (value) => confirmPassword = value!,
                              ).animate().fadeIn(
                                delay: 600.ms,
                                duration: 400.ms,
                              ).slideY(
                                begin: 0.2,
                                duration: 400.ms,
                              ),

                              SizedBox(height: isSmallMobile ? 12 : 20),

                              // Role Dropdown
                              DropdownButtonFormField<String>(
                                style: const TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'I am a',
                                  hintText: 'Select your role',
                                  prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF64748B)),
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
                                initialValue: role,
                                items: ['Donor', 'NGO'].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    role = newValue!;
                                  });
                                },
                              ).animate().fadeIn(
                                delay: 700.ms,
                                duration: 400.ms,
                              ).slideY(
                                begin: 0.2,
                                duration: 400.ms,
                              ),

                              SizedBox(height: isSmallMobile ? 24 : 32),

                              // Sign Up Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () async {
                                          if (_formKey.currentState!.validate()) {
                                            _formKey.currentState!.save();
                                            setState(() {
                                              _isLoading = true;
                                            });

                                            final result = await AuthService.signup(
                                              email,
                                              password,
                                              role,
                                            );

                                            if (!mounted) return;

                                            setState(() {
                                              _isLoading = false;
                                            });

                                            if (result.success) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Signup successful! Please login with your credentials.'),
                                                  backgroundColor: Colors.green,
                                                  duration: Duration(seconds: 2),
                                                ),
                                              );
                                              await Future.delayed(
                                                  const Duration(milliseconds: 500));
                                              if (mounted) {
                                                Navigator.pushReplacementNamed(
                                                    context, '/login');
                                              }
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    result.errorMessage ??
                                                        'Signup failed. Please try again.',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                  duration: const Duration(seconds: 3),
                                                ),
                                              );
                                            }
                                          }
                                        },
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
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Text(
                                          'Sign Up',
                                          style: TextStyle(
                                              fontSize: 16, fontWeight: FontWeight.w600),
                                        ),
                                ),
                              ).animate().fadeIn(
                                delay: 800.ms,
                                duration: 400.ms,
                              ).slideY(
                                begin: 0.2,
                                duration: 400.ms,
                              ),

                              SizedBox(height: isSmallMobile ? 16 : 24),

                              // Login Button
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text.rich(
                                  TextSpan(
                                    text: "Already have an account? ",
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    children: [
                                      TextSpan(
                                        text: 'Login',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: AppTheme.primaryGreen,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate().fadeIn(
                                delay: 900.ms,
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
            );
          },
        ),
      ),
    );
  }
}
