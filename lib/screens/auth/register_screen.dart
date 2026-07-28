import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Registration failed'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _handleOAuthRegister(Future<bool> Function() action) async {
    final authProvider = context.read<AuthProvider>();
    final success = await action();

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Sign up was cancelled'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Go back',
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    const Text(
                      'Create account',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign up free and enjoy 14 days of PawPal Plus. No payment required.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Name field
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                        ).hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Confirm password field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleRegister(),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          tooltip: _obscureConfirmPassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    // Register button
                    ElevatedButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : _handleRegister,
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Sign Up Free'),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Then return to PawPal Base, or choose \$4.99/month or \$29.99/year for Plus. You will not be charged automatically.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: AppTheme.textLight,
                      ),
                    ),
                    if (AppConstants.enableGoogleAuthForCurrentPlatform ||
                        AppConstants.enableAppleAuthForCurrentPlatform) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'or continue with',
                              style: TextStyle(
                                color: AppTheme.textLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (AppConstants.enableGoogleAuthForCurrentPlatform) ...[
                        OutlinedButton.icon(
                          onPressed: authProvider.isLoading
                              ? null
                              : () => _handleOAuthRegister(
                                  authProvider.signInWithGoogle,
                                ),
                          icon: const Icon(Icons.g_mobiledata, size: 24),
                          label: const Text('Continue with Google'),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (AppConstants.enableAppleAuthForCurrentPlatform)
                        OutlinedButton.icon(
                          onPressed: authProvider.isLoading
                              ? null
                              : () => _handleOAuthRegister(
                                  authProvider.signInWithApple,
                                ),
                          icon: const Icon(Icons.apple, size: 24),
                          label: const Text('Continue with Apple'),
                        ),
                    ],
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'By creating an account, you agree to our ',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/terms'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Terms of Service'),
                        ),
                        Text(
                          ' and ',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/privacy'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Privacy Policy'),
                        ),
                        const Text('.'),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Sign in link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        TextButton(
                          onPressed: () => context.pop(),
                          child: const Text('Sign In'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
