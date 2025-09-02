import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isLogin = true;
  bool _isLoading = false;

  // Set this to true when you have an Apple Developer account and Apple Sign-In is configured
  final bool _hasAppleDeveloperAccount = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 40),
                        
                        // Header
                        _buildHeader(),
                        
                        SizedBox(height: 40),
                        
                        // Form Fields
                        _buildFormFields(),
                        
                        SizedBox(height: 24),
                        
                        // Forgot Password (Login only)
                        if (_isLogin) _buildForgotPassword(),
                        
                        SizedBox(height: 32),
                        
                        // Submit Button
                        _buildSubmitButton(),
                        
                        SizedBox(height: 24),
                        
                        // Social Login
                        _buildSocialLogin(),
                        
                        SizedBox(height: 32),
                        
                        // Toggle Auth Mode
                        _buildAuthToggle(),
                      ],
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isLogin ? AppStrings.welcomeBack : AppStrings.createAccount,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        Text(
          _isLogin ? AppStrings.loginSubtitle : AppStrings.signupSubtitle,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        // Name field (signup only)
        if (!_isLogin) ...[
          CustomTextField(
            label: 'Full Name',
            hintText: 'Enter your full name',
            controller: _nameController,
            prefixIcon: Icons.person_outline,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (!_isLogin && (value == null || value.trim().isEmpty)) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          SizedBox(height: 20),
        ],
        
        // Email field
        EmailTextField(
          controller: _emailController,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your email';
            }
            if (!Helpers.isValidEmail(value.trim())) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        
        SizedBox(height: 20),
        
        // Password field
        PasswordTextField(
          controller: _passwordController,
          label: _isLogin ? 'Password' : 'Create Password',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (!_isLogin && value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _showForgotPasswordDialog,
        child: Text(
          'Forgot Password?',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return PrimaryButton(
      text: _isLogin ? 'Login to my account' : 'Create Account',
      onPressed: _handleSubmit,
      isLoading: _isLoading,
      icon: _isLogin ? Icons.login : Icons.person_add,
    );
  }

  // Widget _buildSocialLogin() {
  //   return Column(
  //     children: [
  //       // Divider
  //       Row(
  //         children: [
  //           Expanded(child: Divider(color: AppColors.divider)),
  //           Padding(
  //             padding: EdgeInsets.symmetric(horizontal: 16),
  //             child: Text(
  //               'Or continue with',
  //               style: TextStyle(
  //                 color: AppColors.textSecondary,
  //                 fontSize: 14,
  //               ),
  //             ),
  //           ),
  //           Expanded(child: Divider(color: AppColors.divider)),
  //         ],
  //       ),
        
  //       SizedBox(height: 24),
        
  //       // Google Sign In Button
  //       SecondaryButton(
  //         text: 'Continue with Google',
  //         onPressed: _handleGoogleSignIn,
  //         icon: Icons.g_mobiledata,
  //       ),
  //       if (Platform.isIOS && _hasAppleDeveloperAccount) ...[
  //         SizedBox(height: 16),
  //         SecondaryButton(
  //           text: 'Continue with Apple',
  //           onPressed: _handleAppleSignIn,
  //           icon: Icons.apple,
  //         ),
  //       ],
  //     ],
  //   );
  // }
  Widget _buildSocialLogin() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Divider with text
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.divider)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or continue with',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(child: Divider(color: AppColors.divider)),
          ],
        ),

        SizedBox(height: 24),

        // Side-by-side Google and Apple Sign-In Buttons
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                text: 'Google',
                onPressed: _handleGoogleSignIn,
                icon: Icons.g_mobiledata, // Replace with Google logo if desired
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: SecondaryButton(
                text: 'Apple',
                onPressed: _handleAppleSignIn,
                icon: Icons.apple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAuthToggle() {
    return Center(
      child: TextButton(
        onPressed: _toggleAuthMode,
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            children: [
              TextSpan(
                text: _isLogin
                    ? "Don't have an account? "
                    : "Already have an account? ",
              ),
              TextSpan(
                text: _isLogin ? 'Sign Up' : 'Login',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
    _formKey.currentState?.reset();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);

      if (_isLogin) {
        final result = await firebaseService.signIn(
          _emailController.text.trim(),
          _passwordController.text,
        );
        
        if (result != null) {
          _navigateToHome();
        }
      } else {
        final result = await firebaseService.signUp(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );
        
        if (result != null) {
          _navigateToHome();
        }
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      final result = await firebaseService.signInWithGoogle();
      
      if (result != null) {
        _navigateToHome();
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    // TODO: Implement Apple Sign In
    _showInfoSnackBar('Apple Sign In coming soon!');
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(),
        transitionDuration: Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your email to receive a password reset link.'),
            SizedBox(height: 16),
            EmailTextField(
              controller: _emailController,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          PrimaryButton(
            text: 'Send Reset Link',
            width: 140,
            height: 40,
            onPressed: () async {
              if (_emailController.text.isNotEmpty) {
                try {
                  final firebaseService = Provider.of<FirebaseService>(context, listen: false);
                  await firebaseService.resetPassword(_emailController.text.trim());
                  Navigator.pop(context);
                  _showInfoSnackBar('Password reset link sent to your email');
                } catch (e) {
                  _showErrorSnackBar('Failed to send reset link');
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
