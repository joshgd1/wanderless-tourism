import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/business_auth_provider.dart';
import '../../../../design_system.dart';

class BusinessLoginScreen extends ConsumerStatefulWidget {
  const BusinessLoginScreen({super.key});

  @override
  ConsumerState<BusinessLoginScreen> createState() => _BusinessLoginScreenState();
}

class _BusinessLoginScreenState extends ConsumerState<BusinessLoginScreen> {
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
    ref.read(businessAuthProvider.notifier).clearError();
    final success = await ref.read(businessAuthProvider.notifier).login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (success && mounted) {
      context.go('/business/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(businessAuthProvider);
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: isWide ? _buildWideLayout(authState) : _buildMobileLayout(authState),
      ),
    );
  }

  Widget _buildWideLayout(BusinessAuthState authState) {
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
                        'Manage your\nbusiness.',
                        style: AppText.display.copyWith(
                          color: Colors.white,
                          fontSize: 40,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Track guide performance, manage bookings,\nand grow your tourism operations\nacross Southeast Asia.',
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
              constraints: const BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    _buildBackButton(),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Business Portal', style: AppText.h1),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in to manage your tourism business.',
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

  Widget _buildMobileLayout(BusinessAuthState authState) {
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
                Text('Business Portal', style: AppText.display),
                const SizedBox(height: 6),
                Text(
                  'Sign in to manage your tourism business.',
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

  Widget _buildForm(BusinessAuthState authState) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AppTextField(
            controller: _emailController,
            label: 'Business Email',
            hint: 'business@example.com',
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
              color: AppColors.success,
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
              label: 'Register',
              onPressed: () => context.go('/business/register'),
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
      child: const Icon(Icons.business, color: Colors.white, size: 26),
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

