import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../utils/validators.dart';
import '../widgets/common/common_text_field.dart';
import '../widgets/common/common_gradient_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;
  DateTime? _lastResetAttempt;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateForm);
    _passwordController.removeListener(_validateForm);
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {});
  }

  Future<bool> _isFirebaseInitialized() async {
    try {
      await Firebase.initializeApp();
      return true;
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize Firebase: $e';
      });
      return false;
    }
  }

  Future<void> _login() async {
    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      if (_emailController.text.trim().isEmpty) {
        setState(() {
          _errorMessage = 'Email is required';
        });
      } else if (_passwordController.text.trim().isEmpty) {
        setState(() {
          _errorMessage = 'Password is required';
        });
      }
      return;
    }

    if (!(await _isFirebaseInitialized())) return;

    if (FirebaseAuth.instance.currentUser != null) {
      setState(() {
        _errorMessage = 'You are already logged in';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text.trim();

      if (email.length > 254) {
        setState(() {
          _errorMessage = 'Email is too long';
        });
        return;
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getUserFriendlyError(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email to reset password';
      });
      return;
    }

    if (Validators.validateEmail(email) != null) {
      setState(() {
        _errorMessage = Validators.validateEmail(email);
      });
      return;
    }

    if (!(await _isFirebaseInitialized())) return;

    if (_lastResetAttempt != null &&
        DateTime.now().difference(_lastResetAttempt!).inSeconds < 60) {
      setState(() {
        _errorMessage = 'Please wait before requesting another password reset';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _lastResetAttempt = DateTime.now();
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password reset email sent',
            style: const TextStyle(color: AppColors.textPrimaryDark),
            semanticsLabel: 'Password reset email sent',
          ),
          backgroundColor: AppColors.cardBackground,
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getUserFriendlyError(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Please provide a valid email address.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getUserFriendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'invalid-credential':
        return 'Invalid credentials provided';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppColors.pageGradient),
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: const Text(
                              'Welcome Back',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimaryDark,
                              ),
                              textAlign: TextAlign.center,
                              semanticsLabel: 'Welcome Back',
                            ),
                          ),
                          const SizedBox(height: 24),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: CommonTextField(
                              controller: _emailController,
                              label: 'Email',
                              type: TextInputType.emailAddress,
                              icon: Icons.email,
                              validator: Validators.validateEmail,
                              onChanged: (value) => _validateForm(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: CommonTextField(
                              controller: _passwordController,
                              label: 'Password',
                              type: TextInputType.text,
                              obscureText: true,
                              icon: Icons.lock,
                              validator: Validators.validatePassword,
                              onChanged: (value) => _validateForm(),
                            ),
                          ),
                          if (_errorMessage != null)
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: Container(
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.redAccent.withOpacity(0.1),
                                        Colors.redAccent.withOpacity(0.2),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                    semanticsLabel: _errorMessage,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: CommonGradientButton(
                              text: 'Login',
                              onPressed: () async => await _login(),
                              isLoading: _isLoading,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () => Navigator.pushNamed(context, '/register'),
                                  child: const Text(
                                    'Create an account',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    semanticsLabel: 'Create an account',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () async => await _resetPassword(),
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    semanticsLabel: 'Forgot Password',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                  semanticsLabel: 'Loading',
                ),
              ),
            ),
        ],
      ),
    );
  }
}