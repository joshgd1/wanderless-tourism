import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth_provider.dart';
import '../../../../design_system.dart';

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

  // Wide layout — asymmetrical, brand left + form right
  Widget _buildWideLayout(AuthState authState) {
    return Row(
      children: [
        // Left brand panel
        Expanded(
          flex: 5,
          child: Container(
            color: AppColors.textPrimary,
            child: Stack(
              children: [
                // Subtle geometric pattern
                Positioned.fill(
                  child: CustomPaint(painter: _GridPainter()),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBrandMark(size: 52),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Your journey\nstarts here.',
                        style: AppText.display.copyWith(
                          color: Colors.white,
                          fontSize: 40,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Connect with local guides across\nSoutheast Asia — from Bangkok temples\nto Bali beaches.',
                        style: AppText.body.copyWith(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Tagline
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.brand.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          border: Border.all(color: AppColors.brand.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🌿', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(
                              'Wander less. Worry less.',
                              style: AppText.label.copyWith(
                                color: AppColors.brand,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildFeaturePills(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right form panel
        Expanded(
          flex: 4,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    Text('Sign in', style: AppText.h1),
                    const SizedBox(height: 6),
                    Text(
                      'Welcome back. Enter your details below.',
                      style: AppText.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (authState.error != null) ...[
                      _ErrorBanner(message: authState.error!),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    _buildForm(authState),
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: Text(
                        "Don't have an account? ",
                        style: AppText.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: GhostButton(
                        label: 'Create an account',
                        onPressed: () => context.push('/signup'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const AppDivider(),
                    const SizedBox(height: AppSpacing.md),
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

  // Mobile layout — clean, stacked, minimal
  Widget _buildMobileLayout(AuthState authState) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Minimal top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBrandMark(size: 32),
                IconButton(
                  onPressed: () => context.push('/settings'),
                  icon: const Icon(Icons.settings_outlined, size: 20),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Asymmetrical — left-aligned text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sign in', style: AppText.display),
                const SizedBox(height: 4),
                // Tagline
                Row(
                  children: [
                    Text('🌿', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      'Wander less. Worry less.',
                      style: AppText.bodySmall.copyWith(
                        color: AppColors.brand,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome back.',
                  style: AppText.body.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Form
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
          // Bottom links
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Center(
                  child: Text(
                    "Don't have an account? ",
                    style: AppText.bodySmall,
                  ),
                ),
                const SizedBox(height: 4),
                GhostButton(
                  label: 'Create an account',
                  onPressed: () => context.push('/signup'),
                ),
                const SizedBox(height: AppSpacing.lg),
                const AppDivider(),
                const SizedBox(height: AppSpacing.md),
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

  Widget _buildAlternateActions() {
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
    return Container(
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
    );
  }

  Widget _buildFeaturePills() {
    final features = [
      'Verified local guides',
      '12 SEA countries',
      'Real-time tracking',
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: features.map((f) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Text(
            f,
            style: AppText.caption.copyWith(color: Colors.white.withOpacity(0.7)),
          ),
        );
      }).toList(),
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

// Subtle grid background painter for wide layout
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
