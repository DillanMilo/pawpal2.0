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
          backgroundColor: AppTheme.errorSnackBackground,
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
          backgroundColor: AppTheme.errorSnackBackground,
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
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _PetMosaicHeader(),
                    const SizedBox(height: 10),
                    Text(
                      'Track your pet\'s care,\nhealth, and daily routine',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryText(context),
                        height: 1.05,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to continue to PawPal',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.secondaryText(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const _AuthBrandSignature(),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        isDense: true,
                        prefixIconConstraints: BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
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
                    const SizedBox(height: 10),
                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        isDense: true,
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
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
                    const SizedBox(height: 2),
                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 8),
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
                          : Text('Log In'),
                    ),
                    if (AppConstants.enableGoogleAuthForCurrentPlatform ||
                        AppConstants.enableAppleAuthForCurrentPlatform) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (AppConstants.enableAppleAuthForCurrentPlatform)
                            Expanded(
                              child: SocialAuthButton(
                                compact: true,
                                provider: SocialAuthProvider.apple,
                                onPressed: authProvider.isLoading
                                    ? null
                                    : () => _handleOAuthLogin(
                                        authProvider.signInWithApple,
                                      ),
                              ),
                            ),
                          if (AppConstants.enableAppleAuthForCurrentPlatform &&
                              AppConstants.enableGoogleAuthForCurrentPlatform)
                            const SizedBox(width: 8),
                          if (AppConstants.enableGoogleAuthForCurrentPlatform)
                            Expanded(
                              child: SocialAuthButton(
                                compact: true,
                                provider: SocialAuthProvider.google,
                                onPressed: authProvider.isLoading
                                    ? null
                                    : () => _handleOAuthLogin(
                                        authProvider.signInWithGoogle,
                                      ),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: AppTheme.secondaryText(context),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/register'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text('Sign Up'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 0),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 4,
                      children: [
                        TextButton(
                          onPressed: () => context.push('/privacy'),
                          child: Text('Privacy'),
                        ),
                        TextButton(
                          onPressed: () => context.push('/terms'),
                          child: Text('Terms'),
                        ),
                        TextButton(
                          onPressed: () => context.push('/support'),
                          child: Text('Support'),
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
      height: 102,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            top: 14,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.softTint(context, AppTheme.secondaryColor),
                borderRadius: BorderRadius.circular(32),
              ),
            ),
          ),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 28),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              childAspectRatio: 1.08,
            ),
            itemCount: 3,
            itemBuilder: (context, index) {
              final tile = _tiles[index];
              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.softTint(context, AppTheme.primaryColor),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.surfaceBackground(context),
                    width: 2,
                  ),
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
          const BrandMark(size: 34, withShadow: false),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PawPal',
                style: TextStyle(
                  color: AppTheme.primaryText(context),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              SizedBox(height: 1),
              Text(
                'Pet care tracker',
                style: TextStyle(
                  color: AppTheme.secondaryText(context),
                  fontSize: 11,
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
