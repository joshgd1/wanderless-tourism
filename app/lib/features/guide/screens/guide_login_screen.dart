import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/guide_auth_provider.dart';
import '../../../../design_system.dart';

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
        child: isWide ? _buildWideLayout(authState) : _buildMobileLayout(authState),
      ),
    );
  }

  Widget _buildWideLayout(GuideAuthState authState) {
    return Row(
      children: [
        // Left brand panel — dark
        Expanded(
          flex: 5,
          child: Container(
            color: AppColors.textPrimary,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _GridPainter()),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBrandMark(),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Manage your\nguides.',
                        style: AppText.display.copyWith(
                          color: Colors.white,
                          fontSize: 40,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Track bookings, manage your schedule,\nand grow your tourism business\nacross Southeast Asia.',
                        style: AppText.body.copyWith(
                          color: Colors.white.withOpacity(0.6),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right form
        Expanded(
          flex: 4,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    _buildBackButton(),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Guide Portal', style: AppText.h1),
                    const SizedBox(height: 6),
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
                    const AppDivider(),
                    const SizedBox(height: AppSpacing.md),
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
                _buildBrandMark(),
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

  Widget _buildAltActions() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Are you a tourist?', style: AppText.bodySmall),
            const SizedBox(width: 4),
            GhostButton(
              label: 'Sign In as Tourist',
              onPressed: () => context.go('/login'),
              color: const Color(0xFF25D366),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Don't have an account?", style: AppText.bodySmall),
            const SizedBox(width: 4),
            GhostButton(
              label: 'Register as Guide',
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

  Widget _buildBrandMark() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 26),
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
