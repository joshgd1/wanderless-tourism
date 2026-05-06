import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/guide_auth_provider.dart';
import '../../../../design_system.dart';
import '../../../trip_plan/providers/trip_plan_providers.dart';

class GuideLoginScreen extends ConsumerStatefulWidget {
  const GuideLoginScreen({super.key});

  @override
  ConsumerState<GuideLoginScreen> createState() => _GuideLoginScreenState();
}

class _GuideLoginScreenState extends ConsumerState<GuideLoginScreen> {
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
    ref.read(guideAuthProvider.notifier).clearError();
    final success = await ref.read(guideAuthProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    if (success && mounted) {
      ref.invalidate(openTripPlansProvider);
      context.go('/guide/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(guideAuthProvider);
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: isWide
            ? _buildWideLayout(authState)
            : _buildMobileLayout(authState),
      ),
    );
  }

  Widget _buildWideLayout(GuideAuthState authState) {
    return Row(
      children: [
        // Left brand panel with image
        Expanded(
          flex: 5,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl:
                    'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=1200&q=80',
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    Container(color: AppColors.textPrimary),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black.withOpacity(0.75),
                      Colors.black.withOpacity(0.5),
                      Color(0xFF1E6091).withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xxxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBrandMark(size: 48),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Grow your\nguiding business.',
                      style: AppText.display.copyWith(
                        color: Colors.white,
                        fontSize: 38,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Sign in to manage bookings,\nschedules, and reviews\nacross Southeast Asia.',
                      style: AppText.body.copyWith(
                        color: Colors.white.withOpacity(0.7),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _buildFeatureItem(Icons.calendar_today, 'Manage bookings'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildFeatureItem(Icons.star, 'Build your reputation'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildFeatureItem(Icons.explore, 'Showcase your tours'),
                    const Spacer(),
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
        // Right form panel
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
                    Text('Guide Portal', style: AppText.h1),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to manage your guided tours.',
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
                          Text("Don't have an account? ",
                              style: AppText.bodySmall),
                          GestureDetector(
                            onTap: () => context.push('/guide/register'),
                            child: Text(
                              'Register',
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
                    _buildAltActions(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(GuideAuthState authState) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                _buildBackButton(),
                const Spacer(),
                IconButton(
                  onPressed: () => context.push('/settings'),
                  icon: const Icon(Icons.settings_outlined, size: 20),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBrandMark(size: 48),
                const SizedBox(height: AppSpacing.lg),
                Text('Guide Portal', style: AppText.display),
                const SizedBox(height: 6),
                Text(
                  'Sign in to manage your guided tours.',
                  style: AppText.body.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                if (authState.error != null) ...[
                  _ErrorBanner(message: authState.error!),
                  const SizedBox(height: AppSpacing.md),
                ],
                _buildForm(authState),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const AppDivider(),
                const SizedBox(height: AppSpacing.md),
                _buildAltActions(),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(GuideAuthState authState) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AppTextField(
            controller: _emailController,
            label: 'Guide Email',
            hint: 'guide@example.com',
            prefix: const Icon(Icons.mail_outline,
                size: 18, color: AppColors.textTertiary),
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
            prefix: const Icon(Icons.lock_outline,
                size: 18, color: AppColors.textTertiary),
            obscureText: _obscurePassword,
            suffix: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                size: 18,
                color: AppColors.textTertiary,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              return null;
            },
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
            Expanded(
                child:
                    _SocialButton(icon: Icons.g_mobiledata, label: 'Google')),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _SocialButton(icon: Icons.apple, label: 'Apple')),
          ],
        ),
      ],
    );
  }

  Widget _buildAltActions() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Are you a tourist?', style: AppText.bodySmall),
            const SizedBox(width: 4),
            GhostButton(
              label: 'Sign In',
              onPressed: () => context.go('/login'),
              color: const Color(0xFF25D366),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("No account?", style: AppText.bodySmall),
            const SizedBox(width: 4),
            GhostButton(
              label: 'Register',
              onPressed: () => context.go('/guide/register'),
              color: AppColors.brand,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: IconButton(
        onPressed: () => context.go('/login'),
        icon: const Icon(Icons.arrow_back, size: 18),
        color: AppColors.textSecondary,
      ),
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
  }
}
