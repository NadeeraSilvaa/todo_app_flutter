import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../utils/validators.dart';
import '../widgets/common/common_text_field.dart';
import '../widgets/common/common_gradient_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;

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

    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _nameController.removeListener(_validateForm);
    _emailController.removeListener(_validateForm);
    _passwordController.removeListener(_validateForm);
    _confirmPasswordController.removeListener(_validateForm);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  Future<void> _register() async {
    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      if (_nameController.text.trim().isEmpty) {
        setState(() {
          _errorMessage = 'Name is required';
        });
      } else if (_emailController.text.trim().isEmpty) {
        setState(() {
          _errorMessage = 'Email is required';
        });
      } else if (_passwordController.text.trim().isEmpty) {
        setState(() {
          _errorMessage = 'Password is required';
        });
      } else if (_confirmPasswordController.text.trim().isEmpty) {
        setState(() {
          _errorMessage = 'Confirm Password is required';
        });
      } else if (_passwordController.text != _confirmPasswordController.text) {
        setState(() {
          _errorMessage = 'Passwords do not match';
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
      final name = _nameController.text.trim();

      if (email.length > 254) {
        setState(() {
          _errorMessage = 'Email is too long';
        });
        return;
      }

      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        setState(() {
          _errorMessage = 'User creation failed. Please try again.';
        });
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'displayName': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'themeMode': 'light',
      });

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

  String _getUserFriendlyError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirm Password is required';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return Validators.validatePassword(value);
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
                              'Create Account',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimaryDark,
                              ),
                              textAlign: TextAlign.center,
                              semanticsLabel: 'Create Account',
                            ),
                          ),
                          const SizedBox(height: 24),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: CommonTextField(
                              controller: _nameController,
                              label: 'Name',
                              type: TextInputType.name,
                              icon: Icons.person,
                              validator: Validators.validateName,
                              onChanged: (value) => _validateForm(),
                            ),
                          ),
                          const SizedBox(height: 16),
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
                          const SizedBox(height: 16),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: CommonTextField(
                              controller: _confirmPasswordController,
                              label: 'Confirm Password',
                              type: TextInputType.text,
                              obscureText: true,
                              icon: Icons.lock,
                              validator: _validateConfirmPassword,
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
                              text: 'Register',
                              onPressed: () async => await _register(),
                              isLoading: _isLoading,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: TextButton(
                              onPressed: _isLoading ? null : () => Navigator.pop(context),
                              child: const Text(
                                'Already have an account? Login',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                semanticsLabel: 'Already have an account? Login',
                              ),
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