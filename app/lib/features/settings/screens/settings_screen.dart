import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config.dart';
import '../../../../core/api_client.dart';
import '../../../../design_system.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _urlController = TextEditingController();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    final url = await ApiConfig.getBaseUrl();
    _urlController.text = url.replaceAll('/api', '');
    setState(() {});
  }

  Future<void> _save() async {
    String url = _urlController.text.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    if (!url.endsWith('/api')) {
      url = '$url/api';
    }
    await ApiConfig.setBaseUrl(url);
    await ApiClient.init();
    setState(() => _saved = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _saved = false);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            backgroundColor: AppColors.textPrimary,
            leadingWidth: 0,
            leading: const SizedBox.shrink(),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.textPrimary,
                child: SafeArea(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: GridPainter()),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                        child: Row(
                          children: [
                            _BackBtn(onTap: () => context.pop()),
                            const SizedBox(width: 12),
                            Text(
                              'Settings',
                              style: AppText.h3.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(isWide ? AppSpacing.lg : AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    icon: Icons.cloud_outlined,
                    color: AppColors.success,
                    title: 'Backend Server',
                    description: 'Change this to match your backend server IP address.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Column(
                      children: [
                        AppTextField(
                          controller: _urlController,
                          label: 'Backend URL',
                          hint: 'http://192.168.1.100:8000',
                          prefix: const Icon(Icons.link, size: 18, color: AppColors.textTertiary),
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                            label: _saved ? 'Saved!' : 'Save & Reconnect',
                            icon: _saved ? Icons.check : Icons.save_outlined,
                            onPressed: _save,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _SectionHeader(
                    icon: Icons.help_outline,
                    color: AppColors.info,
                    title: 'Connection Guide',
                    description: null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ConnectionGuideTile(
                    icon: Icons.phone_android,
                    title: 'Android Emulator',
                    description: 'Use the special emulator localhost address',
                    code: 'http://10.0.2.2:8000',
                  ),
                  const Divider(height: AppSpacing.lg),
                  _ConnectionGuideTile(
                    icon: Icons.laptop,
                    title: 'Same WiFi',
                    description: 'Find your PC IP in network settings',
                    code: 'http://<your-pc-ip>:8000',
                  ),
                  const Divider(height: AppSpacing.lg),
                  _ConnectionGuideTile(
                    icon: Icons.cloud,
                    title: 'Cloud / Remote',
                    description: 'Use your cloud server public IP',
                    code: 'http://<remote-ip>:8000',
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _BackBtn({required this.onTap});

  @override
  State<_BackBtn> createState() => _BackBtnState();
}

class _BackBtnState extends State<_BackBtn> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _isHovered ? Colors.white.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(Icons.arrow_back, color: Colors.white.withOpacity(_isHovered ? 1 : 0.7), size: 20),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? description;

  const _SectionHeader({
    required this.icon,
    required this.color,
    required this.title,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.h3),
              if (description != null) ...[
                const SizedBox(height: 2),
                Text(description!, style: AppText.bodySmall),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ConnectionGuideTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String code;

  const _ConnectionGuideTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 20, color: AppColors.textTertiary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.labelBold),
              Text(description, style: AppText.caption),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            code,
            style: AppText.caption.copyWith(
              color: AppColors.success,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}

