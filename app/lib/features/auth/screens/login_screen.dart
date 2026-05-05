import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/auth_provider.dart';
import '../../../../design_system.dart';
import '../../../features/discover/screens/discover_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).clearError();
    final success = await ref.read(authProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    if (success && mounted) {
      ref.invalidate(mlMatchesProvider);
      ref.invalidate(matchesProvider);
      context.go('/discover');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: isWide ? _buildWideLayout(authState) : _buildMobileLayout(authState),
      ),
    );
  }

  // Wide layout — image background left + white form card right
  Widget _buildWideLayout(AuthState authState) {
    return Row(
      children: [
        // ── Left brand panel with image ───────────────────────────────────
        Expanded(
          flex: 5,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              CachedNetworkImage(
                imageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200&q=80',
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(color: AppColors.textPrimary),
              ),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black.withOpacity(0.75),
                      Colors.black.withOpacity(0.5),
                      Color(0xFF0B5C3A).withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xxxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBrandMark(size: 48),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Your next\nadventure awaits.',
                      style: AppText.display.copyWith(
                        color: Colors.white,
                        fontSize: 38,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Sign in to connect with local guides\nacross Southeast Asia.',
                      style: AppText.body.copyWith(
                        color: Colors.white.withOpacity(0.7),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _buildFeatureItem(Icons.check_circle_outline, 'Curated experiences'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildFeatureItem(Icons.check_circle_outline, 'Verified local experts'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildFeatureItem(Icons.check_circle_outline, 'Real-time trip tracking'),
                    const Spacer(),
                    // Decorative circles
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Opacity(
                        opacity: 0.3,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // ── Right form panel ─────────────────────────────────────────────
        Expanded(
          flex: 4,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    Text('Welcome back', style: AppText.h1),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to continue your journey.',
                      style: AppText.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (authState.error != null) ...[
                      _ErrorBanner(message: authState.error!),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    _buildForm(authState),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSocialLogin(),
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Don't have an account? ", style: AppText.bodySmall),
                          GestureDetector(
                            onTap: () => context.push('/signup'),
                            child: Text(
                              'Sign up',
                              style: AppText.bodySmall.copyWith(
                                color: AppColors.brand,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _buildAlternateActions(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Mobile layout — image hero top + form below
  Widget _buildMobileLayout(AuthState authState) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero image header
          SizedBox(
            height: 220,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&q=80',
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: AppColors.textPrimary),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBrandMark(size: 40),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Your next\nadventure awaits.',
                          style: AppText.h2.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Form
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back', style: AppText.h2),
                const SizedBox(height: 4),
                Text(
                  'Sign in to continue your journey.',
                  style: AppText.bodySmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (authState.error != null) ...[
                  _ErrorBanner(message: authState.error!),
                  const SizedBox(height: AppSpacing.md),
                ],
                _buildForm(authState),
                const SizedBox(height: AppSpacing.lg),
                _buildSocialLogin(),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Don't have an account? ", style: AppText.bodySmall),
                      GestureDetector(
                        onTap: () => context.push('/signup'),
                        child: Text(
                          'Sign up',
                          style: AppText.bodySmall.copyWith(
                            color: AppColors.brand,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildAlternateActions(),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(AuthState authState) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AppTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'you@example.com',
            prefix: const Icon(Icons.mail_outline, size: 18, color: AppColors.textTertiary),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _passwordController,
            label: 'Password',
            prefix: const Icon(Icons.lock_outline, size: 18, color: AppColors.textTertiary),
            obscureText: _obscurePassword,
            suffix: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                size: 18,
                color: AppColors.textTertiary,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => context.push('/forgot-password'),
              child: Text(
                'Forgot your password?',
                style: AppText.caption.copyWith(color: AppColors.brand),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Sign in',
              isLoading: authState.isLoading,
              onPressed: _login,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLogin() {
    return Column(
      children: [
        const AppDivider(),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text('or continue with', style: AppText.caption),
            ),
            Expanded(child: Divider(color: AppColors.border)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: _SocialButton(icon: Icons.g_mobiledata, label: 'Google')),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _SocialButton(icon: Icons.apple, label: 'Apple')),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.brand),
        const SizedBox(width: 10),
        Text(
          text,
          style: AppText.body.copyWith(color: Colors.white.withOpacity(0.9)),
        ),
      ],
    );
  }

  Widget _buildAlternateActions() {
    final isWide = MediaQuery.of(context).size.width > 600;

    if (!isWide) {
      return Column(
        children: [
          const Divider(height: AppSpacing.xl),
          Text(
            'Are you a guide?',
            style: AppText.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Sign in as Guide',
              onPressed: () => context.push('/guide/login'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push('/guide/register'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: AppColors.brand),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: Text(
                'Register as Guide',
                style: AppText.label.copyWith(color: AppColors.brand),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Business owner?',
            style: AppText.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: SecondaryButton(
              label: 'Sign in as Business',
              onPressed: () => context.push('/business/login'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => context.push('/business/register'),
              child: Text(
                'Register as Business',
                style: AppText.label.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _AltActionRow(
          label: 'Business owner?',
          linkLabel: 'Sign in',
          onLinkTap: () => context.push('/business/login'),
          suffix: 'or',
          onSuffixTap: () => context.push('/business/register'),
          suffixLabel: 'register',
        ),
        const SizedBox(height: AppSpacing.sm),
        _AltActionRow(
          label: 'Are you a guide?',
          linkLabel: 'Sign in',
          onLinkTap: () => context.push('/guide/login'),
          suffix: 'or',
          onSuffixTap: () => context.push('/guide/register'),
          suffixLabel: 'register',
        ),
      ],
    );
  }

  Widget _buildBrandMark({required double size}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Image.asset(
        'assets/images/wanderless_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.brand,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            Icons.explore,
            color: Colors.white,
            size: size * 0.55,
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SocialButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message.replaceAll('Exception: ', ''),
              style: AppText.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _AltActionRow extends StatelessWidget {
  final String label;
  final String linkLabel;
  final VoidCallback onLinkTap;
  final String suffix;
  final VoidCallback onSuffixTap;
  final String suffixLabel;

  const _AltActionRow({
    required this.label,
    required this.linkLabel,
    required this.onLinkTap,
    required this.suffix,
    required this.onSuffixTap,
    required this.suffixLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: AppText.bodySmall),
        const SizedBox(width: 4),
        GhostButton(label: linkLabel, onPressed: onLinkTap),
        Text(suffix, style: AppText.bodySmall),
        const SizedBox(width: 4),
        GhostButton(
          label: suffixLabel,
          onPressed: onSuffixTap,
          color: AppColors.brand,
        ),
      ],
    );
  }
}
