import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth_provider.dart';
import '../../../../design_system.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).clearError();
    final success = await ref.read(authProvider.notifier).register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
    );
    if (success && mounted) {
      context.go('/onboarding');
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

  Widget _buildWideLayout(AuthState authState) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Container(
            color: AppColors.textPrimary,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: GridPainter()),
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
                        'Start your\nadventure.',
                        style: AppText.display.copyWith(
                          color: Colors.white,
                          fontSize: 40,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Join thousands of travelers\nfinding authentic local\nguides across Southeast Asia.',
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
        Expanded(
          flex: 4,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    _buildBackButton(),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Create Account', style: AppText.h1),
                    const SizedBox(height: 6),
                    Text(
                      'Join WanderLess to find authentic local guides.',
                      style: AppText.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (authState.error != null) ...[
                      _ErrorBanner(message: authState.error!),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    _buildForm(authState),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(AuthState authState) {
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
                Text('Create Account', style: AppText.display),
                const SizedBox(height: 6),
                Text(
                  'Join WanderLess to find authentic local guides.',
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
          const SizedBox(height: AppSpacing.xl),
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
            controller: _nameController,
            label: 'Full Name',
            hint: 'John Smith',
            prefix: const Icon(Icons.person_outline, size: 18, color: AppColors.textTertiary),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Name is required';
              if (v.trim().length < 2) return 'Name too short';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _emailController,
            label: 'Email Address',
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
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            prefix: const Icon(Icons.lock_outline, size: 18, color: AppColors.textTertiary),
            obscureText: _obscureConfirm,
            suffix: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                size: 18,
                color: AppColors.textTertiary,
              ),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (v) {
              if (v != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Create Account',
              isLoading: authState.isLoading,
              onPressed: _signup,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Already have an account?', style: AppText.bodySmall),
              const SizedBox(width: 4),
              GhostButton(
                label: 'Sign In',
                onPressed: () => context.pop(),
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
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
        onPressed: () => context.pop(),
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
      child: const Icon(Icons.explore, color: Colors.white, size: 26),
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

