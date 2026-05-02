import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config.dart';
import '../../../../design_system.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GuideRegisterScreen extends ConsumerStatefulWidget {
  const GuideRegisterScreen({super.key});

  @override
  ConsumerState<GuideRegisterScreen> createState() => _GuideRegisterScreenState();
}

class _GuideRegisterScreenState extends ConsumerState<GuideRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _bioController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/guides/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'bio': _bioController.text.trim(),
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Registration successful! Please sign in.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
          );
          context.go('/guide/login');
        }
      } else {
        final data = jsonDecode(response.body);
        setState(() => _error = data['detail'] ?? 'Registration failed');
      }
    } catch (e) {
      setState(() => _error = 'Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: isWide ? _buildWideLayout() : _buildMobileLayout(),
      ),
    );
  }

  Widget _buildWideLayout() {
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
                        'Become a\nguide.',
                        style: AppText.display.copyWith(
                          color: Colors.white,
                          fontSize: 40,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Share your expertise, earn income,\nand connect with travelers\nacross Southeast Asia.',
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
                    Text('Guide Registration', style: AppText.h1),
                    const SizedBox(height: 6),
                    Text(
                      'Create your guide account to start accepting tours.',
                      style: AppText.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (_error != null) ...[
                      _ErrorBanner(message: _error!),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    _buildForm(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
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
                Text('Guide Registration', style: AppText.display),
                const SizedBox(height: 6),
                Text(
                  'Create your guide account to start accepting tours.',
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
                if (_error != null) ...[
                  _ErrorBanner(message: _error!),
                  const SizedBox(height: AppSpacing.md),
                ],
                _buildForm(),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AppTextField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'Your full name',
            prefix: const Icon(Icons.person_outline, size: 18, color: AppColors.textTertiary),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Name is required';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _emailController,
            label: 'Email Address',
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
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18, color: AppColors.textTertiary),
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
            obscureText: _obscureConfirmPassword,
            suffix: IconButton(
              icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, size: 18, color: AppColors.textTertiary),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _bioController,
            label: 'Bio (optional)',
            hint: 'Tell tourists about yourself and your expertise...',
            prefix: const Icon(Icons.description_outlined, size: 18, color: AppColors.textTertiary),
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Create Account',
              isLoading: _isLoading,
              onPressed: _register,
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
                onPressed: () => context.go('/guide/login'),
                color: AppColors.brand,
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
        onPressed: () => context.go('/guide/login'),
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
      child: const Icon(Icons.person_add, color: Colors.white, size: 26),
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
            child: Text(message, style: AppText.bodySmall.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
