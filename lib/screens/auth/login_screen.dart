import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/social_auth_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Login failed'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _handleOAuthLogin(Future<bool> Function() action) async {
    final authProvider = context.read<AuthProvider>();
    final success = await action();

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Sign in was cancelled'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
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
                    const SizedBox(height: 20),
                    const _PetMosaicHeader(),
                    const SizedBox(height: 24),
                    const Text(
                      'Track your pet\'s care,\nhealth, and daily routine',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        height: 1.05,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in to continue to PawPal',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    const _AuthBrandSignature(),
                    const SizedBox(height: 24),
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
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
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
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _handleLogin,
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
                          : const Text('Log In'),
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
                      if (AppConstants.enableAppleAuthForCurrentPlatform) ...[
                        SocialAuthButton(
                          provider: SocialAuthProvider.apple,
                          onPressed: authProvider.isLoading
                              ? null
                              : () => _handleOAuthLogin(
                                  authProvider.signInWithApple,
                                ),
                        ),
                        if (AppConstants.enableGoogleAuthForCurrentPlatform)
                          const SizedBox(height: 12),
                      ],
                      if (AppConstants.enableGoogleAuthForCurrentPlatform)
                        SocialAuthButton(
                          provider: SocialAuthProvider.google,
                          onPressed: authProvider.isLoading
                              ? null
                              : () => _handleOAuthLogin(
                                  authProvider.signInWithGoogle,
                                ),
                        ),
                    ],
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        TextButton(
                          onPressed: () => context.push('/register'),
                          child: const Text('Sign Up'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 4,
                      children: [
                        TextButton(
                          onPressed: () => context.push('/privacy'),
                          child: const Text('Privacy'),
                        ),
                        TextButton(
                          onPressed: () => context.push('/terms'),
                          child: const Text('Terms'),
                        ),
                        TextButton(
                          onPressed: () => context.push('/support'),
                          child: const Text('Support'),
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

class _PetMosaicHeader extends StatefulWidget {
  const _PetMosaicHeader();

  @override
  State<_PetMosaicHeader> createState() => _PetMosaicHeaderState();
}

class _PetMosaicHeaderState extends State<_PetMosaicHeader> {
  late final List<_MosaicTileData> _tiles = _randomizedTiles();

  List<_MosaicTileData> _randomizedTiles() {
    final tiles = <_MosaicTileData>[
      const _MosaicTileData('assets/images/auth/dog_1.jpg'),
      const _MosaicTileData('assets/images/auth/cat_1.jpg'),
      const _MosaicTileData('assets/images/auth/rabbit_1.jpg'),
      const _MosaicTileData('assets/images/auth/dog_2.jpg'),
      const _MosaicTileData('assets/images/auth/cat_2.jpg'),
      const _MosaicTileData('assets/images/auth/hamster_1.jpg'),
    ];
    tiles.shuffle(Random());
    return tiles;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            top: 28,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.softMint,
                borderRadius: BorderRadius.circular(32),
              ),
            ),
          ),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.82,
            ),
            itemCount: _tiles.length,
            itemBuilder: (context, index) {
              final tile = _tiles[index];
              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.softLavender,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: AppTheme.softShadow,
                  image: DecorationImage(
                    image: AssetImage(tile.assetPath),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AuthBrandSignature extends StatelessWidget {
  const _AuthBrandSignature();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'PawPal pet care tracker',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const BrandMark(size: 44, withShadow: false),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'PawPal',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Pet care tracker',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MosaicTileData {
  final String assetPath;

  const _MosaicTileData(this.assetPath);
}
